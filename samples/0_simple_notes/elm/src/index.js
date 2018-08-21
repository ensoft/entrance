'use strict';

// Require index.html so it gets copied to dist
require('./index.html');

const dev_mode = true; // Overridden by build_prod script
const websocketProtocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
const port = dev_mode ? 8000 : location.port;
const websocket = `${websocketProtocol}//${location.hostname}:${port}/ws`;

var Elm = require('./Main.elm');
Elm.Main.fullscreen({websocket: websocket});
