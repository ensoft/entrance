# ConfiguredFeature base class
#
# Copyright (c) 2018 Ensoft Ltd

import logging

from .base import Feature
from ..exceptions import EntranceError

log = logging.getLogger(__name__)


class ConfiguredFeature(Feature):
    """
    A feature that is started by configuration, once per websocket
    """

    # Dictionary of configuration options and default values
    config = {}

    def __init__(self, ws_handler, config):
        """
        Merge in any specifed configuration with our defaults
        """
        super().__init__(ws_handler)
        for key, val in config.items():
            if key in self.config:
                self.config[key] = val
            else:
                msg_parts = [
                    'Invalid config item "{}" for feature {}'.format(key, self.name),
                    'Possible items are: {}'.format(sorted(self.config.keys())),
                ]
                log.critical(
                    "\n!!\n!!\n!! %s\n!!\n!!\n!!",
                    "\n!! ".join(msg_parts)
                )
                raise EntranceError(". ".join(msg_parts))

    @classmethod
    def all(cls):
        """
        List all subclasses
        """
        # for now assume a flat subclass hierarchy
        return cls.__subclasses__()
