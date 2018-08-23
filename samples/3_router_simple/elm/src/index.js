'use strict';

// Require index.html so it gets copied to dist
require('./index.html');
require('./style.scss');

const dev_mode = true; // Overridden by build_prod script
const debugger_present = true; // Overridden by build_prod script
const websocketProtocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
const port = dev_mode ? 8000 : location.port;
const websocket = `${websocketProtocol}//${location.hostname}:${port}/ws`;

var Elm = require('./Main.elm');
var app = Elm.Main.fullscreen({
  websocket: websocket,
  debuggerPresent: debugger_present
});

/*
 * Elm port that injects CSS changes to show/hide the Elm debugger
 */
var css_node = document.createElement('style');
document.body.appendChild(css_node);
function show_debugger (visible) {
    css_node.innerHTML = ".elm-overlay { display: {}; }".replace(/{}/,
                                                visible ? "block" : "none");
}
app.ports.showDebugger.subscribe(show_debugger);
show_debugger(false);
