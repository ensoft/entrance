# EnTrance

[EnTrance](https://github.com/ensoft/entrance) is a framework for writing
simple but robust web apps, with a particular set of characteristics. It uses a
Python 3.5+ asyncio backend, and an Elm frontend, communicating over a
websocket.

This package provides the server-side functionality.

Reading the documentation and sample applications in [the primary
repo](https://github.com/ensoft/entrance) is recommended. Simple examples for
writing your own Python server-side feature are in [sample
2](https://github.com/ensoft/entrance/blob/master/samples/2_shell/svr/run.py)
and [sample
3](https://github.com/ensoft/entrance/blob/master/samples/3_browser/svr/run.py).

By default, the dependencies for this package cover the core functionality.
There is also a rich set of optional capability for interacting with routers,
that has a much more extended set of PyPi dependencies. If you want to use
this, then depend on `entrance[with-router-features]` rather than just `entrance`.
