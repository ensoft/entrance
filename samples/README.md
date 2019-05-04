# Example apps

This directory includes a few sample apps to help get you started. They have
very little functionality, in order to lay bare the "other stuff" that is of
interest here:

 - [Sample 1](1_notes) is a very basic note-taking app, showing a minimal Elm
   app with no custom server-side Python.
 - [Sample 2](2_shell) lets you execute arbitrary shell commands on the server,
   and shows a minimal example of writing [your own server-side Python
   feature](2_shell/svr/run.py) and the corresponding [Elm client
   library](2_shell/elm/src/InsecureShell.elm).
 - [Sample 3](3_browser) provides a basic directory browser for exploring the
   server-side filesystem layout, showing a slightly more complex example of a
   [custom server-side Python feature](3_browser/svr/run.py) and corresponding
   [Elm client library](3_browser/elm/src/ReadDir.elm).
 - [Sample 4](4_router_simple) is a basic but full-featured application for
   interacting with IOS-XR routers. It shows how to use some more
   "production-oriented" features, such as multiple channels, server restarts,
   and packaging up the entire application into a single binary for easy
   distribution.

Even though they are simple, they should exhibit the robustness properties of
the EnTrance framework. For all examples, you can try things like:

 - killing the server process
 - pausing (ctrl-z) the server process
 - spawning multiple client tab/windows
 - changing the messaging on client and/or server to introduce bugs

and even though there is almost no explicit code for such cases, you should see
a reasonable representation to the app user of what's going on. They also all
include SASS for CSS styling, static web assets like `png` files, and a dual
dev/prod means of development:

- a "dev build" (with `yarn dev`, see below) runs on port 3000 by default, and
  supports live updates on the client-side. So you can make a change to a
  `.elm`/`.scss`/`.png`/whatever file, and near-instantly see the effect in the
  running application in your browser after you save the file. The Elm debugger
  is also enabled.

- a "prod build" (with `./build_prod`, see below) runs on port 8000 by default,
  is compiled with optimisation and no Elm debugger, and can optionally be
  packaged up with the server into a single binary.

In all cases, the `svr` directory includes a mandatory `config.yml` file to
specify enabled capabilities. (I suspect it would be better to be able to omit
this, and have a sensible default, but this isn't the case right now.) You can
override common things like the port number (default 8000) either here or using
command-line overrides - use `-h` to see.

You can also optionally provide a `logging.yml` file in the same `svr`
directory that gives fine-grained control over server logging. The default (if
you don't) is to be fairly chatty on the console, and really chatty into a
rotated file called `debug.log`. In particular, if you see signs of a Python
exception or other problem on the console, then looking in the `debug.log` file
should give you all the available context to help debug that.

## How to run them

The repo already contains a static `.js` file including the compiled Elm code,
so all you need to run a sample is Python (version 3.5 or later). Just:

 - cd to the `svr` directory for a sample
 - run `./make-venv` to install all the dependencies (including the `entrance`
   Python package itself) from PyPi
 - run either `./run` or `./run.py` (only one exists for each sample)

If you're simply editing server-side Python, then this is sufficient. More
likely, you want to edit Elm too. In this case, first (optionally but highly
recommended) get a good Elm editor environment:

- Install the [latest Elm compiler](https://guide.elm-lang.org/install.html)
  (mostly just for editor and repl support - the one used for building the app
  will be installed in a local sandbox by yarn)
- Install [elm-format](https://github.com/avh4/elm-format/releases/) and
  configure your editor to use it on file save

To build a development image:

- Ensure you have a reasonably recent
  [node installation](https://nodejs.org/en/download/)
- Ensure you have [yarn installed](https://yarnpkg.com/lang/en/docs/install/)
- cd to the `elm` directory for a sample
- run `yarn` once to initialise everything
- then run `yarn dev` to get a development server for the frontend
- manually start the Python server using `./run` or `./run.py` from the
  `svr` directory as above to provide the backend
- point your web browser at http://localhost:1234

When you're ready to commit, build a production image:

- run `./build_prod` to create assets for the standalone server
- test by running the Python server as above and going to http://localhost:8000
- `git commit` if everything looks good

The development server and runtime asset compilation is provided by
[Parcel](https://parceljs.org). By design this has minimal configuration and
operates somewhat by convention, so if you deviate from the samples, you may
need to look up up how it handles your particular assets.

One artefact of the way Parcel works is that almost all the assets in the
`svr/static` directory get an 8-digit hex hash code added to their filenames.
This is intended for production use with CDNs (where different file contents
get a different filename) but in the samples is configured to be static (so we
can commit the assets into the repo without the filename changing every time).
It isn't possible to just turn the hashing fully off (at the time of writing).


# Testing local changes to the EnTrance library packages

The sample apps here just pull the production EnTrance packages as dependencies
from the public package servers:

 * A [Python package on PyPi](https://pypi.org/project/entrance/) that
   implements all the generic/built-in server functionality.

 * An [Elm package on elm-package](https://package.elm-lang.org/packages/ensoft/entrance/latest/)
   that implements all the generic/built-in client functionality.

 * A [Javascript package on npm](https://www.npmjs.com/package/entrance-ws)
   that implements ports for WebSockets (since the Elm package was removed
   in 0.19).

However, you might be using them to test local changes to one or more of these
packages. If that's the case, then it's easy to temporarily change them to
include the local code, rather than fetching the production version from a
public package repository.

Remember to reverse these modifications before finishing up your changes :)

## Python

In the `svr` directory, `rm -rf venv`, and rather than call `./make-venv`,
instead do:

        python3 -m venv venv
        venv/bin/pip3 install --upgrade ../../../python

where the `../../..` is the path to the root of the repo. You can re-run the
second line to update the venv with any subsequent changes.

## Elm

In the `elm` directory, remove the `ensoft/entrance` entry from `elm.json`, and
`ln -s ../../../elm/src/EnTrance src`.

You'll need to temporarily include the following dependencies in your app if
you don't have them (`elm install remotedata` will do the trick):

  - elm/bytes
  - elm/file
  - elm/http
  - elm/parser
  - krisajenkins/remotedata

## Javascript

In the `elm/src` directory, `ln -s ../../../../npm/index.js ws.js`, and in
`main.js`, change the line:

        import { handleWebsocket } from 'entrance-ws';

to:

        import { handleWebsocket } from './ws.js';
