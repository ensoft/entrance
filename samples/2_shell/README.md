# Shell exec sample app

This is an example of a minimal EnTrance application that uses a custom
server-side Python feature plugin. In this case, it just blindly executes
whatever shell commands the client sends it.

See [here](../README.md) for how to build/run/modify. The client (Elm) side has
the usual live-updating development mode. If you modify the Python backend, you
need to manually restart the server using `./run.py` from the `svr` directory.
