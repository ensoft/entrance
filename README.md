# EnTrance

EnTrance is a framework for writing simple but robust web apps, using a 
Python 3.5+ asyncio backend, and an Elm frontend.

Communication between the frontend and backend is via JSON messages sent
asynchronously over a websocket. Websocket connectivity is typically required
for the frontend to function. The backend is fully generic, but happens to come
with particularly rich built-in options for communicating with routers.

This is an early commit, and is a bit sparse on documentation. The `samples`
directory has some simple example apps. A design document is in the `docs` 
directory in the repo; this explains concepts and terminology required to 
fully understand the APIs for both Elm and Python.

The single repo includes both the Python package (published in PyPi) and 
the Elm package (published in elm-package).
