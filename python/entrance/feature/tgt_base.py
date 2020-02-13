# ConnectionFeature base class
#
# Copyright (c) 2018 Ensoft Ltd

import logging, time

from ..connection import connection_factory_by_name, ConState, Connection
from .._util import events
from .dyn_base import DynamicFeature

log = logging.getLogger(__name__)


class TargetFeature(DynamicFeature):
    """
    A feature that has one or more connections to a target (eg a router). Always
    optional, because we don't want connection initiation unless needed by the
    application.
    """

    #
    # Schema
    #
    requests = {"connect": ["connection_type", "params"], "disconnect": []}

    notifications = ["connection_state"]

    #
    # Implementation
    #
    def __init__(self, ws_handler, channel, target, original_request):
        """
        Initialize the connections we actively own.
        """
        super().__init__(ws_handler, channel, target, original_request)
        self.children = set()
        self.state = ConState.DISCONNECTED
        self.parent_target_group = None
        self.connect_requested = False

        # If the client has requested connection state updates, then set up
        # the common part of each notification message now
        if original_request.get("con_state_subscribe", False):
            self.state_subscription_nfn = {
                "nfn_type": "connection_state",
                "feature": self.name,
            }
            if "id" in original_request:
                self.state_subscription_nfn["id"] = original_request["id"]
        else:
            self.state_subscription_nfn = None

    async def do_connect(self, connection_type, params):
        """
        Create a connection factory and start connecting
        """
        self.connect_requested = True
        if params.get("auth_is_password", True):
            params["password"] = params["secret"]
        else:
            params["ssh_key"] = params["secret"]
        conn_factory_cls = connection_factory_by_name[connection_type]
        self.conn_factory = conn_factory_cls(**params)
        # Actually do it
        await self.connect(self.conn_factory)

    async def do_disconnect(self):
        """
        Disconnect from remote protocol peers
        """
        # We shouldn't be asked to disconnect if it wasn't us who connected
        # originally
        if not self.connect_requested:
            log.info(
                "%s disconnecting, although we didn't connect originally", self.name
            )
        self.connect_requested = False
        # Actually do it
        await self.disconnect()

    async def connect(self, conn_factory):
        """
        Actually kick off the outgoing connections - implemented by subclasses
        """
        assert False

    async def disconnect(self):
        """
        Disconect
        """
        # Connections can be removed mid-iteration if they disconnect promptly
        safe_iter = list(self.children)
        for child in safe_iter:
            events.create_checked_task(child.disconnect())

    def add_connection(self, connection, from_scratch=False):
        """
        Associate a Connection object with this Feature object, for the purposes
        of global connection state monitoring
        """
        if from_scratch:
            self.children = set()
        self.children.add(connection)
        connection.add_state_listener(self.state_listener)

    async def state_listener(self, child):
        """
        Callback when one of our feature's connections changes state
        """
        if child not in self.children:
            # Possible race condition - a dying connection is still talking
            # to us, but we don't care any more
            return

        # Calculate aggregate state across all child connections/features
        self.state = child.state
        for c in self.children:
            if c.state > self.state:
                self.state = c.state

        # Send the notification if we were asked to
        if self.state_subscription_nfn is not None:

            def encode_state(state):
                return {
                    "state": state.name,
                    "error": state.failure_reason if state.is_failure() else "",
                }

            nfn = self.state_subscription_nfn.copy()
            nfn["child"] = child.name
            nfn["child_state"] = encode_state(child.state)
            nfn["feature"] = self.name
            nfn["state"] = encode_state(self.state)
            nfn["state_is_up"] = self.state == ConState.CONNECTED
            nfn["timestamp"] = time.strftime("%H:%M:%S")
            await self._notify(**nfn)

        # Independently notify our target manager, if there is one
        if self.parent_target_group is not None:
            await self.parent_target_group.state_listener(self)

        # If a connection object has disconnected, then throw it away - we'll
        # create a new one if there's another connection request later
        if child.state == ConState.DISCONNECTED and isinstance(child, Connection):
            self.children.remove(child)
