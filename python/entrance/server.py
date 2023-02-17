# EnTrance server
#
# Copyright (c) 2023 Ensoft Ltd

import logging
import sys

import sanic
import sanic.response

from . import WebsocketHandler


log = logging.getLogger(__name__)


def create_app(config, file_location) -> sanic.Sanic:
    """
    Create a simple server with the specified configuration.

    If an app needs more elaborate setup, then just copy this function
    and modify.

    """

    app = sanic.Sanic(name="entrance-app", log_config=None)
    app.config.RESPONSE_TIMEOUT = 3600
    app.config.KEEP_ALIVE_TIMEOUT = 75

    # Websocket handling
    @app.websocket("/ws")
    async def handle_ws(request, ws):
        log.info("New websocket client")
        ws_handler = WebsocketHandler(ws, config["features"])
        await ws_handler.handle_incoming_requests()

    # Static file handling
    #
    # Note:
    # The order of 'app.static()' and route declarations (with '@app.route()')
    # matters here. For static to be a fallback it should come after route
    # declarations, e.g. if a route path contains a parameter.
    static_dir = file_location + config["start"]["static_dir"]
    app.static("/", static_dir)

    @app.route("/")
    async def home_page(request):
        return await sanic.response.file(static_dir + "/index.html")

    return app
