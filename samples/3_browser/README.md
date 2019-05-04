# Directory browser sample app

This is an example of an EnTrance application with a custom server-side Python
feature plugin that inclues some more realistic message complexity. It just
browses the directory structure as seen by the server; extending this to view
files that seem sensibly-sized ascii (or graphics files like PNG or JPG) is a
good exercises for the reader.

See [here](../README.md) for how to build/run/modify. The client (Elm) side has
the usual live-updating development mode. If you modify the Python backend, you
need to manually restart the server using `./run.py` from the `svr` directory.
