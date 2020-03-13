# CLI config feature
#
# Copyright (c) 2018 Ensoft Ltd

from .tgt_base import TargetFeature


class CLIConfigFeature(TargetFeature):
    """
    Feature that enters configuration via the CLI
    """

    #
    # Schema
    #
    name = "cli_config"
    requests = {
        "cli_config_load": ["config"],
        "cli_config_commit": ["check_only"],
        "cli_config_get_failures": [],
        "cli_config_get_unsupported": [],
    }

    #
    # Implementation
    #
    async def connect(self, conn_factory):
        """
        Connect and get ready for the next commit request
        """
        self.connection = await conn_factory.get_cli_connection(
            "config", finalizer=self.finalizer
        )
        self.add_connection(self.connection, from_scratch=True)

    async def finalizer(self):
        """
        Finalize a new connection
        """
        await self.connection.send("configure\n", override=True)
        await self.connection.expect_prompt(override=True)

    async def do_cli_config_load(self, config):
        """
        Load up a config buffer with some CLI
        """
        # Clear any previous confiuration in the session
        await self.connection.send("clear\n")
        await self.connection.expect_prompt()

        # Enter the new configuration
        errors = []
        for line in config.split("\n"):
            await self.connection.send(line + "\n")
            result = await self.connection.expect_prompt()
            if len(result) > len(line) + 4:
                errors.append(result)

        # Check for parser-rejected syntax errors
        if len(errors) > 0:
            return self._rpc_failure("\n".join(errors))
        else:
            return self._rpc_success()

    async def do_cli_config_commit(self, check_only=False):
        """
        Commit a config buffer populated with cli_config_load
        """
        command = "validate commit" if check_only else "commit"
        await self.connection.send(command + "\n")
        result = await self.connection.expect_prompt()
        if len(result) > 200:
            return self._rpc_failure(result)
        else:
            return self._rpc_success()

    async def do_cli_config_get_failures(self):
        """
        Get config errors
        """
        await self.connection.send("show configuration failed\n")
        result = await self.connection.expect_prompt(strip_top=True)
        result = result.strip()
        if len(result):
            return self._rpc_failure(result)
        else:
            return self._rpc_success()

    async def do_cli_config_get_unsupported(self):
        """
        Get config items that are unsupported by validation
        """
        await self.connection.send("show configuration validation unsupported\n")
        result = await self.connection.expect_prompt(strip_top=True)
        result = result.strip()
        if result == "% No such configuration item(s)":
            return self._rpc_success()
        else:
            return self._rpc_failure(result)
