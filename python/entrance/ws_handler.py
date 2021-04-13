# Overall handler for a single websocket
#
# Copyright (c) 2018 Ensoft Ltd

from collections import defaultdict
import asyncio, logging
import ujson
from websockets.exceptions import ConnectionClosed
from .connection import ConState
from .feature import *
from ._util import events

log = logging.getLogger(__name__)

# Once: normalize the Feature schemas, so that subclasses pick up the supported
# requests or notifications from their ancestor classes
Feature.normalize_schema()

# Turn multiple args into a single flat key for dict lookups
def _mktuple(*args):
    return "||".join(args)


class WebsocketHandler:
    """
    Class that holds a set of Feature modules, and handles the mux/demux so
    that they all share a single websocket in a sensible fashion. One of these
    objects is instantiated for each client session.
    """

    def __init__(self, ws, feature_config):
        self.ws = ws
        self.conn_factory = None
        self.request_map_default = {}
        self.request_map_optional = {}
        self.features = []
        self.target_features = defaultdict(list)
        self.target_group = {}
        self.con_state_listeners = []

        # Start out with just the configured features
        for feature_cls in ConfiguredFeature.all():
            name = feature_cls.name
            if name in feature_config:
                log.debug("Adding configured feature %s", name)
                self.add_feature(feature_cls(self, feature_config[name]))
            else:
                log.debug("Skipping unconfigured feature %s", name)

    async def handle_incoming_requests(self):
        """
        Mini-event loop that listens for incoming requests and handles them
        """
        while True:
            got_req = False
            try:
                req = await self.ws.recv()
                got_req = True
            except (asyncio.CancelledError, ConnectionClosed):
                log.info("Websocket closed")
                for feature in self.features:
                    feature.close()
                break
            except Exception as e:
                log.error("Websocket recv exception: %s", e)
            try:
                if got_req:
                    await self._handle_req(req)
            except Exception as e:
                log.error(
                    "Exception during _handle_req: %s (see debug.log for details)", e
                )
                log.debug(
                    "_handle_req exception details", exc_info=True, stack_info=True
                )
                await self.notify_error(str(e))

    async def _handle_req(self, raw_request):
        """
        Handle an incoming request by dispatching to the appropriate Feature
        """
        request = ujson.loads(raw_request)
        request["userid"] = "default"  # no auth features yet
        req_type = request["req_type"]
        channel = request["channel"]
        target = request.get("target", "")
        if req_type != "ping":
            log.debug("WS RECV: %s", abbreviate(request))

        # Dispatch the request
        try:
            # First try default features - these are keyed just off req_type,
            # and are executed synchronously (since they are supposed to be
            # quick, and can include meta-operations like starting new features)
            feature = self.request_map_default[req_type]
            await feature.handle(request)
        except KeyError:
            # Fall back to optional features - these are keyed off the
            # <req_type, channel, target> triple, and are executed
            # asynchronously, to avoid head-of-line blocking in complex
            # message processing
            try:
                key = _mktuple(req_type, channel, target)
                feature = self.request_map_optional[key]
                events.create_checked_task(feature.handle(request))
            except KeyError:
                log.warning("Un-handleable request {}".format(request))
                log.debug(
                    "key = {}, request_map_optional = {}".format(
                        key, self.request_map_optional
                    )
                )
                await self.notify_error(
                    "Don't know how to handle request {}".format(request)
                )
                return

    async def notify(self, **nfn):
        """
        Send a specific outbound notification
        """
        if nfn["nfn_type"] != "pong":
            log.debug("WS SEND: {}".format(abbreviate(nfn)))
        json = ujson.dumps(nfn)
        await self.ws.send(json)

    async def notify_error(self, error, **nfn):
        """
        Send an outbound error, caught by the frontend's app top level
        """
        await self.notify(channel="error", nfn_type="error", value=error, **nfn)

    def add_feature(self, feature, channel=None, target=None):
        """
        Add a feature instance
        """
        self.features.append(feature)
        if isinstance(feature, ConfiguredFeature):
            # Configured feature: just add the handled request_types to the
            # default request map
            for req_type in feature.requests.keys():
                self.request_map_default[req_type] = feature
        else:
            # Dynamic feature: add the <request_type, channel, target> triple
            # to the optional request map
            assert isinstance(feature, DynamicFeature)
            for req_type in feature.requests.keys():
                key = _mktuple(req_type, channel, target)
                self.request_map_optional[key] = feature

            if isinstance(feature, TargetGroupFeature):
                # Remember target groups
                self.target_group[feature.target] = feature

            # All target features need their own collection
            if isinstance(feature, TargetFeature):
                parent_target = feature.parent_target
                if parent_target is not None:
                    self.target_features[parent_target].append(feature)
                    if parent_target in self.target_group:
                        self.target_group[parent_target].add_feature(feature)

    async def remove_feature(self, feature, channel, target):
        """
        Remove a dynamic feature instance
        """
        assert isinstance(feature, DynamicFeature)

        # Remove from the request map
        for req_type in feature.requests.keys():
            key = _mktuple(req_type, channel, target)
            del self.request_map_optional[key]

        if isinstance(feature, TargetGroupFeature):
            # Forget from set of target groups
            del self.target_group[feature.target]

            # The dying feature's children will just forget about it. Harsh.
            for child in feature.children:
                child.parent_target_group = None

        # Same for the dying feature's parents. Even harsher.
        if isinstance(feature, TargetFeature):
            parent_target_group = feature.parent_target_group
            if parent_target_group is not None:
                # First consider the dying feature to be disconnected, so the
                # parent feature recomputes its overall state
                saved_state = feature.state  # bit of a hack
                feature.state = ConState.DISCONNECTED
                await parent_target_group.state_listener(feature)
                feature.state = saved_state  # at least hack over now

                # Then actually make your parents forget you, Hermione
                parent_target_group.remove_feature(feature)
            if feature.parent_target is not None:
                self.target_features[feature.parent_target].remove(feature)

    def get_features_for_target(self, target):
        """
        Return all target features for a given target
        """
        return self.target_features[target]


MAX_LENGTH = 200


def abbreviate(msg):
    """
    Helper function to make logging safer and saner
    """
    val = msg.copy()
    if isinstance(val, dict):
        for k, v in val.items():
            if k == "secret" and isinstance(v, str):
                val[k] = "*" * len(v)
            elif isinstance(v, str) and len(v) > MAX_LENGTH:
                val[k] = v[0:MAX_LENGTH] + "..."
            elif isinstance(v, dict):
                val[k] = abbreviate(v)
    return val
