# Netconf feature
#
# Copyright (c) 2018 Ensoft Ltd

from .tgt_base import TargetFeature


class NetconfFeature(TargetFeature):
    """
    Feature that exposes Netconf operations
    """

    #
    # Schema
    #
    name = "netconf"
    requests = {"netconf": ["op", "__req__"]}

    # We decode out the actual netconf op as follows
    op_requests = {
        "get": ["value"],
        "get_config": ["value"],
        "edit_config": ["value"],
        "commit": [],
        "validate": [],
        "discard_changes": [],
    }

    #
    # Implementation
    #
    async def connect(self, conn_factory):
        """
        Connect and get ready for the next commit request
        """
        self.connection = await conn_factory.get_netconf_connection("netconf")
        self.add_connection(self.connection, from_scratch=True)

    async def do_netconf(self, op, req):
        """
        Do one of the netconf operations specified in op_requests
        """
        try:
            fn = getattr(self.connection, op)
            args = [req[arg] for arg in self.op_requests[op]]
            rpc_reply = await fn(*args)
            result = str(rpc_reply)

            # Semi-hack for commit check:
            #
            # If a validate operation returns errors, but they all have
            # severity 'warning' not 'error', then consider the operation
            # a success
            if (
                op == "validate"
                and not rpc_reply.ok
                and not "<error-severity>error</error-severity>" in result
            ):
                return self._rpc_success(result)

            # Usual processing
            elif rpc_reply.ok:
                return self._rpc_success(result)
            else:
                return self._rpc_failure(result)

        except Exception as e:
            return self._rpc_failure(str(e))
