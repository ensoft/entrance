#!venv/bin/python3
#
# Server component of demo app
#
# This provides an example of how to provide your own custom features
# outside of the 'entrance' package.
#
# Since this is a configured feature, you need your config.yaml file
# to include it, otherwise your feature won't be started.

import logging, os
from pathlib import Path

import entrance
from entrance.feature.cfg_base import ConfiguredFeature

# For production use, this wouldn't require any additional logging.
# But including this here as an example of helping you debug
# your own features. All logs below are gratuitous.
log = logging.getLogger(__name__)


class DirectoryFeature(ConfiguredFeature):
    """
    Feature that enables reading server-side directories
    """

    # Feature name, started in config.yml (or by name by the client if it were
    # a dynamic feature instead)
    name = "directory"

    # Message schema: accept one request, named 'read_dir', with one argument,
    # of name 'path', and send an RPC reply.
    requests = {"read_dir": ["path"]}

    # do_thing is called whenever a request of name 'thing' is received. So
    # this is the implementation of the 'read_dir' request. This should always
    # return either self._rpc_success(value) or self._rpc_failure(err_string).
    async def do_read_dir(self, path):
        log.debug("Received read_dir request for path {}".format(path))
        # Canonicalise the path to avoid things like double-slashes
        path = str(Path(path).resolve())
        try:
            items = []
            for item in os.scandir(path):
                if item.is_dir():
                    item_type = "dir"
                elif item.is_file() and not item.is_symlink():
                    item_type = "file"
                else:
                    item_type = "special"
                items.append({"name": item.name, "type": item_type})

            items.sort(key=lambda x: x["name"])
            result = {"full_path": path, "entries": items}
            log.debug("read_dir returning success: {}".format(result))
            return self._rpc_success(result)

        except Exception as e:
            log.warning("read_dir failure: {}".format(e))
            return self._rpc_failure(str(e))


# Start up
entrance.main()
