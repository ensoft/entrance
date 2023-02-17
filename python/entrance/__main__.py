# EnTrance default application start
#
# Copyright (c) 2018 Ensoft Ltd

import argparse, functools, logging, logging.config, sys
import sanic, sanic.worker.loader, yaml

from . import server
from ._util import logger

log = logging.getLogger(__name__)
location = getattr(sys, "_MEIPASS", ".") + "/"  # where pre-canned files live


def parse_args(args):
    """
    Parse command-line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--port", help="override port")
    parser.add_argument("-a", "--addr", help="override bind address")
    parser.add_argument("-d", "--debug", action="store_true", help="debug to console")
    parser.add_argument(
        "-c", "--config", default=location + "config.yml", help="config file"
    )
    parser.add_argument("-l", "--logging", help="logging definition file")
    return parser.parse_args(args)


def main(*args, task=None):
    # Load up preferences
    opts = parse_args(args)

    # Config file is always required. The logging file may fall back
    # to the default yaml file below if unspecified.
    main_config = yaml.safe_load(open(opts.config).read())
    if opts.logging is None:
        logging_yaml = logging_yaml_default
    else:
        logging_yaml = open(opts.logging).read()
    logging_config = yaml.safe_load(logging_yaml)

    # Apply any command-line overrides
    if opts.port is not None:
        main_config["start"]["port"] = opts.port
    if opts.addr is not None:
        main_config["start"]["host"] = opts.addr
    if opts.debug:
        logging_config["handlers"]["console"]["level"] = "DEBUG"

    # Go
    logging.config.dictConfig(logging_config)
    logging.setLogRecordFactory(logger.FormattedLogRecord)

    loader = sanic.worker.loader.AppLoader(
        factory=functools.partial(server.create_app, main_config, location)
    )
    app = loader.load()

    # Optionally invoke a caller-specified task once the event loop is up
    if task is not None:
        app.add_task(task)

    start_cfg = main_config["start"]
    log.info(
        "Starting app with %s",
        ", ".join(["{}={}".format(k, v) for k, v in start_cfg.items()]),
    )

    # Enter event loop
    app.prepare(host=start_cfg["host"], port=int(start_cfg["port"]), dev=False, motd=False)
    sanic.Sanic.serve(primary=app, app_loader=loader)

    log.info("Closing down gracefully")


# Default logging.yml file
logging_yaml_default = """
# Separate configuration file for logging, since most end-users care less
# about the details of this
version: 1
disable_existing_loggers: false
formatters:
    brief:
        format: "%(levelname)s: [%(name)s] %(message)s"
    normal:
        format: "%(asctime)s %(levelname)s: [%(name)s] %(message)s"
handlers:
    console:
        class: logging.StreamHandler
        level: INFO
        formatter: brief
        stream: ext://sys.stdout
    debug:
        class: logging.handlers.RotatingFileHandler
        level: DEBUG
        formatter: normal
        filename: debug.log
        maxBytes: 1000000
        backupCount: 3
        encoding: utf8
loggers:
    "":
        level: DEBUG
        handlers: [console, debug]
    asyncio:
        level: DEBUG
        handlers: [debug]
    paramiko:
        level: WARNING
        handlers: [console, debug]
    ncclient:
        level: WARNING
        handlers: [console, debug]
    network:
        level: DEBUG
        handlers: [debug]
    sanic:
        level: WARNING
        handlers: [debug]
    websockets:
        level: WARNING
        handlers: [console, debug]
"""

if __name__ == "__main__":
    main(*sys.argv[1:])
