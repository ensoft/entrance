# DynamicFeature base class
#
# Copyright (c) 2018 Ensoft Ltd

from .base import Feature

class DynamicFeature(Feature):
    """
    A feature that is started only when the client requests it, and thus can
    be instantiated more than once per endpoint (with distinct target values)
    """
    def __init__(self, ws_handler, endpoint, target, original_request):
        """
        Remember our endpoint, target, and original request (which contains
        any other parameters specific to particular subclasses)
        """
        super().__init__(ws_handler)
        self.endpoint = endpoint
        self.target = target
        # Parent target is which target we should flock under - same as target
        # for everything other than connection groups
        self.parent_target = target
        self.original_req = original_request

    async def _notify(self, **nfn):
        """
        Insert the target and endpoint into any outgoing notifications
        """
        nfn['endpoint'] = self.endpoint
        nfn['target'] = self.target
        await super()._notify(**nfn)

    @classmethod
    def find(cls, name):
        """
        Look up a concrete subclass by "name" field
        """
        return _find(cls, name)

def _find(cls, name):
    """
    Recursively find the named subclass
    """
    for c in cls.__subclasses__():
        if c.name == name:
            return c
        v = _find(c, name)
        if v is not None:
            return v
