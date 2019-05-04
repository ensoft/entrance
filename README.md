# EnTrance

EnTrance is a framework for writing simple but robust web apps, using a Python
asyncio backend, and an Elm frontend. It is oriented around classical
distributed systems design: the goal is to provide a reliable async
bidirectional message channel between client and server, each of which have a
sound modular decomposition, and then get out the way.

EnTrance might be a good fit if your application needs:

 - a rich "single page app" user interface
 - some custom backend functionality too
 - robust behaviour and simple code

and can assume:

 - any app-specific backend logic is expressible in asyc Python
 - it's ok for the app to "freeze" if network connectivity fails persistently
   (eg rural 2G flaky cellular access) although temporary glitches should be
   handled gracefully

If so, then EnTrance allows easy expression of the specific client- and
server-side logic unique to your app, and factors out most of the effort in
engineering a reliable distributed system.

There are other incidental features, such as the ability to package the whole
app into a single (server-side) executable for easy distribution.

The backend logic is modular, with a unit of function being termed a "feature".
A set of reusable features are included in the Python `entrance` package, that
can be used if you wish (they happen to be particularly capable at interacting
with routers) but you can totally ignore these, and it is also easy to write
any app-specific functionality.

This is an early commit, and is a bit sparse on documentation. The
[samples](https://github.com/ensoft/entrance/tree/master/samples) directory has
some simple example apps. A design document is in the
[docs](https://github.com/ensoft/entrance/tree/master/docs) directory; this
explains concepts and terminology required to fully understand the APIs for
both Elm and Python.

The single repo has the source for three separate packages:

- A [Python package on PyPi](https://pypi.org/project/entrance) for the server
- An [Elm package on
  elm-package](https://package.elm-lang.org/packages/ensoft/entrance/latest) for
  the client
- A [Javascript package on npm](https://www.npmjs.com/package/entrance-ws) that
  implements ports for WebSockets (since the Elm package was removed in 0.19)
