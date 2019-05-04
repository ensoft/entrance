# EnTrance WebSocket support

[EnTrance](https://github.com/ensoft/entrance) is a framework for writing a
particular style of web app, using a modular Python asyncio backend and an Elm
frontend, that communicate over a websocket.

Elm 0.19 removed support for websockets, so this npm module restores this. (In
fact, it can tailor the functionality more exactly to the EnTrance
requirements, so large Elm apps end up rather simpler than before.)
