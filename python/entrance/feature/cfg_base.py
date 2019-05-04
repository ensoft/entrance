# ConfiguredFeature base class
#
# Copyright (c) 2018 Ensoft Ltd

import logging, sys
from .base import Feature

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
                log.critical('\n!!\n!!\n!! Invalid config item "{}" for feature {}\n'
                          '!! Possible items are: {}\n!!\n!!\n!!'.format(
                              key, self.name, sorted(self.config.keys())))
                sys.exit(1)

    @classmethod
    def all(cls):
        """
        List all subclasses
        """
        # for now assume a flat subclass hierarchy
        return cls.__subclasses__()
