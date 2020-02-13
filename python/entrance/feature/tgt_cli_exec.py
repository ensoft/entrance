# CLI Exec feature
#
# Copyright (c) 2018 Ensoft Ltd

from .tgt_base import TargetFeature


class CLIExecFeature(TargetFeature):
    """
    Feature that submits CLI exec requests directly
    """

    #
    # Schema
    #
    name = "cli_exec"
    requests = {"cli_exec": ["command"]}

    #
    # Implementation
    #
    async def connect(self, conn_factory):
        """
        Connect and get ready for future cli_exec requests
        """
        self.connection = await conn_factory.get_cli_connection(
            "cli_exec", self.finalizer
        )
        self.add_connection(self.connection, from_scratch=True)

    async def finalizer(self):
        """
        Finalize a new connection
        """
        await self.connection.send("run stty rows 0\n", override=True)
        await self.connection.expect_prompt(override=True)

    async def do_cli_exec(self, command):
        """
        Do a single CLI exec command
        """
        await self.connection.send(command + "\n")
        output = await self.connection.expect_prompt()
        m = self.connection._interesting.search(output)
        if m:
            return self._rpc_success(m.group(1))
        else:
            return self._rpc_failure(output)
