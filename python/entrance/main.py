# EnTrance server
#
# Copyright (c) 2023 Ensoft Ltd

import logging
import os

from fastapi import FastAPI, WebSocket
from fastapi.staticfiles import StaticFiles
from starlette.responses import FileResponse

from . import WebsocketHandler, settings

log = logging.getLogger(__name__)


app = FastAPI()


# Websocket handling
@app.websocket("/ws")
async def handle_ws(ws: WebSocket):
    log.info("New websocket client")
    await ws.accept()
    ws_handler = WebsocketHandler(ws, settings.main_config["features"])
    await ws_handler.handle_incoming_requests()


@app.get("/")
async def home_page():
    return FileResponse(os.path.join(settings.get_static_dir(), "index.html"))


app.mount("/", StaticFiles(directory=settings.get_static_dir()), name="static")
