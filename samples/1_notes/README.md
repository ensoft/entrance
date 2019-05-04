# Note-taking sample app

This is a pretty minimal EnTrance application, with no custom server-side
Python. Even so, it is a reasonable base for a simple application, including
Elm project structure, CSS, static assets etc.

See [here](../README.md) for how to build/run/modify, including the
live-updating-with-debugger development mode. As noted there, the app is
decently robust against common failure scenarios (especially given the lack of
code explicity to handle such things). It isn't Google Docs though: in
particular, if you make an edit near-simultaneously from two different browser
tabs/windows, then only one change will win. (The other one should still
display the correct end result to the user though.)
