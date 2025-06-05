# EnTrance default application start
#
# Copyright (c) 2018 Ensoft Ltd

import argparse
import logging
import logging.config
import sys

import uvicorn
import yaml

from . import settings
from ._util import logger

log = logging.getLogger(__name__)


def main(*args):
    # Load up preferences
    settings.parse(args)

    # Go
    logging.config.dictConfig(settings.logging_config)
    logging.setLogRecordFactory(logger.FormattedLogRecord)

    start_cfg = settings.main_config["start"]
    log.info(
        "Starting app with %s",
        ", ".join(["{}={}".format(k, v) for k, v in start_cfg.items()]),
    )

    config = uvicorn.Config(
        "entrance.main:app",
        host=start_cfg["host"],
        port=int(start_cfg["port"]),
        log_config=settings.logging_config,
        timeout_keep_alive=75,
        ws_ping_interval=600, # 10 minutes
    )
    server = uvicorn.Server(config)

    # Enter event loop
    server.run()

    log.info("Closing down gracefully")

if __name__ == "__main__":
    main(*sys.argv[1:])
