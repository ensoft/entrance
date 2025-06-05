# EnTrance settings and CLI argument parsing
#
# Copyright (c) 2025 Ensoft Ltd

import argparse
import os
import sys

import yaml

_LOCATION = getattr(sys, "_MEIPASS", ".") + "/"  # where pre-canned files live


main_config = {}
logging_config = {}


def get_static_dir():
    """
    Return the location of the static files
    """
    return os.path.join(_LOCATION, main_config["start"]["static_dir"])


def parse(args) -> argparse.Namespace:
    """
    Parse command-line arguments
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--port", help="override port")
    parser.add_argument("-a", "--addr", help="override bind address")
    parser.add_argument(
        "-d", "--debug", action="store_true", help="debug to console"
    )
    parser.add_argument(
        "-c", "--config", default=_LOCATION + "config.yml", help="config file"
    )
    parser.add_argument("-l", "--logging", help="logging definition file")

    args = parser.parse_args(args)

    global main_config
    global logging_config

    # Config file is always required. The logging file may fall back
    # to the default yaml file below if unspecified.
    with open(args.config) as f:
        main_config = yaml.safe_load(f.read())

    if args.logging is None:
        logging_yaml = logging_yaml_default
    else:
        with open(args.logging) as f:
            logging_yaml = f.read()
    logging_config = yaml.safe_load(logging_yaml)

    # Apply any command-line overrides
    if args.port is not None:
        main_config["start"]["port"] = args.port
    if args.addr is not None:
        main_config["start"]["host"] = args.addr
    if args.debug:
        logging_config["handlers"]["console"]["level"] = "DEBUG"


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
