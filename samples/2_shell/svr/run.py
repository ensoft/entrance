#!venv/bin/python3
#
# Server component of demo app
#
# This provides an example of how to provide your own custom features
# outside of the 'entrance' package.
#
# Since this is a configured feature, you need your config.yaml file
# to include it, otherwise your feature won't be started.

import asyncio, logging
from asyncio.subprocess import PIPE

import entrance
from entrance.feature.cfg_base import ConfiguredFeature

# For production use, this wouldn't require any additional logging.
# But including this here as an example of helping you debug
# your own features. All logs below are gratuitous.
log = logging.getLogger(__name__)


class InsecureShellFeature(ConfiguredFeature):
    """
    Feature that runs a shell command with zero security
    """

    # Feature name, started in config.yml (or by name by the client if it were
    # a dynamic feature instead)
    name = "insecure_shell"

    # Message schema: accept one request, named 'insecure_shell_cmd', with one
    # argument, of name 'cmd', and send an RPC reply.
    requests = {"insecure_shell_cmd": ["cmd"]}

    # do_thing is called whenever a request of name 'thing' is received. So
    # this is the implementation of the 'insecure_shell_cmd' request. This
    # should always return exactly one of:
    #  - self._rpc_success(value)
    #  - self._rpc_failure(err_string).
    async def do_insecure_shell_cmd(self, cmd):
        log.debug("Received insecure_shell_cmd[{}]".format(cmd))

        try:
            proc = await asyncio.create_subprocess_shell(cmd, stdout=PIPE, stderr=PIPE)
            stdout, stderr = await proc.communicate()
            return self._rpc_success(
                dict(stdout=stdout, stderr=stderr, exit_code=proc.returncode)
            )

        except Exception as e:
            log.warning("create_subprocess_shell failure: {}".format(e))
            return self._rpc_failure(str(e))


# Start up
entrance.main()
