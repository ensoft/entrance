# Base for Feature and its non-concrete subclasses
#
# Copyright (c) 2018 Ensoft Ltd

import logging

from ..exceptions import EntranceError

log = logging.getLogger(__name__)


class Feature:
    """
    Base class for a plugin that handles some set of Websocket request types.
    Classes should not subclass this directly, but instead one of the
    ConfiguredFeature or DynamicFeature subclasses.
    """

    # Name for the feature - concrete subclasses must have one
    name = None

    # Requests (with arguments) that a subclass accepts
    requests = {}

    # Notifications that a subclass sends. None can be used as an RPC reply
    notifications = [None]

    def __init__(self, ws_handler):
        self.ws_handler = ws_handler

    def close(self):
        """
        Websocket has closed
        """
        pass

    @classmethod
    def normalize_schema(feature_cls):
        """
        Ensure that each Feature subclass's schema includes any requests and
        notifications from its parent classes. In addition, add 'None' as a
        permissible notification type, since this is used for RPC replies, and
        automatically permit each req_type as a nfn_type (for use in replies)
        """

        def normalize_cls(current_cls, parent_cls):
            current_cls.requests = {**current_cls.requests, **parent_cls.requests}
            current_cls.notifications = frozenset(
                set(current_cls.notifications)
                | set(parent_cls.notifications)
                | current_cls.requests.keys()
            )
            for child_cls in current_cls.__subclasses__():
                normalize_cls(child_cls, current_cls)

        for cls in feature_cls.__subclasses__():
            normalize_cls(cls, feature_cls)

    async def handle(self, req):
        """
        Handle incoming websocket requests
        """
        try:
            # Extract out the request type and the arguments it wants. A magic
            # argument name of '__req__' means supply the entire request, and
            # and argument name starting with '?' is optional (value None if
            # unspecified)
            req_type = req["req_type"]
            arg_names = self.requests[req_type]

            def get_arg(arg):
                if arg == "__req__":
                    return req
                elif arg.startswith("?"):
                    return req.get(arg[1:], None)
                else:
                    return req[arg]

            args = [get_arg(arg) for arg in arg_names]
        except KeyError:
            # Couldn't extract the request type and arguments as per the
            # supplied schema. Can't proceed.
            log.info("Received an unparseable JSON request")
            await self._notify(
                nfn_type="error",
                channel="error",
                value="Unparseable JSON request: {}".format(req),
            )
            return

        # Do the operation
        try:
            result = await getattr(self, "do_" + req_type)(*args)
        except Exception as e:
            msg = "Exception handling {}({})".format(
                req_type, ", ".join(str(arg) for arg in args)
            )
            log.error(msg + " (see debug.log for details)")
            log.debug("Exception details", exc_info=True, stack_info=True)
            result = self._rpc_failure(msg)

        # Return a notification with the result if provided
        if result is not None:
            # Reflect back the mandatory "channel" and optional "id" from the
            # client, plus if the nfn_type is missing then insert the req_type
            # (as is typical for eg RPCs)
            result["channel"] = req["channel"]
            if "id" in req:
                result["id"] = req["id"]
            if "target" in req:
                result["target"] = req["target"]
            if result.get("nfn_type", None) is None:
                result["nfn_type"] = req_type
            await self.ws_handler.notify(**result)

    def _check_nfn_type(self, nfn_type):
        """
        Check that we're conforming to our own schema declaration
        """
        if nfn_type not in self.notifications:
            msg = "Feature {} trying to send disallowed notification {}".format(
                self.name, nfn_type)
            log.critical("\n!!\n!!\n!! %s\n!!\n!!", msg)
            raise EntranceError(msg)

    async def _notify(self, **nfn):
        """
        Helper method to send an outgoing notification. Can be overidden by
        subclasses (eg to ensure additional fields are set)
        """
        self._check_nfn_type(nfn["nfn_type"])
        await self.ws_handler.notify(**nfn)

    def _result(self, nfn_type, value=None, **kwargs):
        """
        Compose a result dict. Always needs a nfn_type, quite often has a value,
        and otherwise has other key-value pairs.
        """
        self._check_nfn_type(nfn_type)
        kwargs["nfn_type"] = nfn_type
        if value is not None:
            kwargs["value"] = value
        return kwargs

    def _rpc_success(self, result="", **kwargs):
        """
        Compose a result dict for an RPC reply after success
        """
        # nfn_type of None means use the original req_type
        return self._result(nfn_type=None, result=result, **kwargs)

    def _rpc_failure(self, error="", **kwargs):
        """
        Compose a result dict for an RPC reply after failure
        """
        # nfn_type of None means use the original req_type
        return self._result(nfn_type=None, error=error, **kwargs)
