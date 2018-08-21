# Example apps

This directory includes a few sample apps to help get you started.

Note that the apps here just pull the production EnTrance packages as
dependeicies from the public PyPi/elm-package servers, rather than directly
using any changes that might be in this local repo.

## `0_simple_notes`

A minimal EnTrance application. Has just a single Elm file, no CSS, no static assets, no Python. Intended for reading first, to get the hang of how things are put together.

Don't use this as the basis for a real project though, since it's too limited.
Even so, there are still some interesting development features:

* You run a 'production build' by going to the `svr` directory, running
`./make-venv` and following the instructions (`venv/bin/python3 -m entrance`.)
This serves the version of the Elm app that has been previously compiled into
`svr/static/app.js` on port 8000. You'll probably get server errors about no
`favicon.ico` when you point a browser at it - this is a (benign) side-effect
of having no static assets. You'll also need Internet connectivity to pick up
the Bootstrap CSS file from a CDN.

* The must be a `config.yml` file to specify enabled capabilities (just use the
default one provided). You can also override common things like the port number
using command-line overrides - use `-h` to see. You can also optionally specify
a `logging.yml` file that gives fine-grained control over logging.

* For interactive development, run the server, but then go to the `elm`
directory and run `yarn dev` (a simple `yarn` is required once for a fresh
clone). If you use port 3000, you will see a dynamic compilation of the Elm
source, that usually auto-reloads whenever you hit edit an Elm source file.
(Sometimes a manual refresh is required.) You also have access to the Elm
debugger in this mode. (Note that this mode of development requires the server
to be running on port 8000.)

* Once you're happy with some Elm changes, run `./build_prod` to update the copy of `app.js` in `svr/static` and commit your code.

## `1_notes`

Pretty much the same app as `0_simple_notes`, but this time in a more full-featured setting. This is a better bet for using as the basis for your own apps (although still no custom Python yet):

 * Multiple Elm files, in a sensible structure for a very simple app
 * Local static assets
 * Integrated CSS (using SASS). So development on port 3000 should immediately display changes to `.scss` files, and `./build_prod` compiles the changes into
 what will be served in production on port 8000.

