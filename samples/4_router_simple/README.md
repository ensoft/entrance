# Router interaction sample app

This is a simple "production-ready" app, exhibiting several aspects not
revealed by the simpler samples:

 - A complex Elm structure, requiring multiple channels
 - "Toasts" (that pop up, geddit?) for transient notification display
 - Use of the EnTrance features for communicating with routers, including
   things like login credentials and aggregating multiple connection states
   into one simplified aggregate state
 - The ability to request a restart from the client (if the server is
   configured to accept this)
 - Packaging [the entire application into a single (architecture-dependent)
   binary](svr/make-single-binary) for easy distribution

See [here](../README.md) for how to build/run/modify. The client (Elm) side has
the usual live-updating development mode. If you modify the Python backend, you
need to manually restart the server using `./run.py` from the `svr` directory.

Syntax highlighting for XML is provided by
[highlightjs](https://highlightjs.org); the `elm/src/static/highlight.pack.js`
file in the static assets was not simply downloaded from that site, but had to
be amended as per [this GitHub highlight.js
issue](https://github.com/highlightjs/highlight.js/issues/1245#issuecomment-242865524)
(even though that issue is ~2.5 years old).

This sample app still uses only a single "target" (ie talks to only a single
router at a time, albeit over multiple connections). If your app requires
simultaneous connectivity to more than one router, then look at the
[Target](https://package.elm-lang.org/packages/ensoft/EnTrance/latest/EnTrance-Feature-Target)
documentation.
