# Feature implementing core functionality
#
# Copyright (c) 2018 Ensoft Ltd

import logging, os
from .cfg_base import ConfiguredFeature
from .dyn_base import DynamicFeature
from .tgt_base import TargetFeature

log = logging.getLogger(__name__)


class CoreFeature(ConfiguredFeature):
    """
    Feature to manage core services
    """

    #
    # Schema
    #
    name = "core"

    requests = {
        "force_restart": [],
        "ping": [],
        "start_feature": ["feature", "channel", "target", "__req__"],
        "stop_feature": ["feature", "channel", "target"],
    }

    notifications = ["pong"]

    config = {"allow_restart_requests": False, "allowed_dynamic_features": None}

    #
    # Implementation
    #
    def __init__(self, ws_handler, config):
        super().__init__(ws_handler, config)
        self.started_features = {}

    async def do_force_restart(self):
        """
        Forcibly restart the server (assuming started by the "run" script)
        """
        if self.config["allow_restart_requests"]:
            os._exit(42)
        else:
            return self._rpc_failure("Restart disallowed by configuration")

    async def do_ping(self):
        """
        Respond to a keepalive message from the client
        """
        return self._result("pong")

    async def do_start_feature(self, feature_name, channel, target, req):
        """
        Start an optional feature
        """
        allowed = self.config["allowed_dynamic_features"]
        if allowed is not None and feature_name not in allowed:
            return self._rpc_failure(
                "Feature {} is disallowed by configuration".format(feature_name)
            )
        feature_cls = DynamicFeature.find(feature_name)
        new_feature = feature_cls(self.ws_handler, channel, target, req)
        self.ws_handler.add_feature(new_feature, channel, target)
        self.started_features[_fk(feature_name, channel, target)] = new_feature

    async def do_stop_feature(self, feature_name, channel, target):
        """
        Stop an optional feature
        """
        feature_key = _fk(feature_name, channel, target)
        feature = self.started_features[feature_key]
        await self.ws_handler.remove_feature(feature, channel, target)
        try:
            del self.started_features[feature_key]
        except KeyError:
            # probably some race condition
            log.debug(
                "Ignoring missing started feature %s on stop_feature request",
                feature_key,
            )

        if isinstance(feature, TargetFeature):
            # Might as well try a disconnect
            log.debug("About to disconnect stopped feature " + feature_key)
            await feature.disconnect()


def _fk(feature_name, channel, target):
    """Construct a dict key for a feature instance"""
    return "{}::{}::{}".format(feature_name, channel, target)
