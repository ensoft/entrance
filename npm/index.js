'use strict';

// Handle all the EnTrance websocket stuff, now that Elm 0.19
// has removed the standard WebSocket package. We make this
// replacement channel-aware, to reduce the Elm boilerplate
// previously required in complex apps.


// Hmmm, mutable global state. Lovely!
var ws_url;
var ws;
var ws_up = false;
var channels = {};
var isup_ports = [];
var errorRecv;
var seq_num = 1;
var wanted_seq_num = {};

// Reserved port names
const reserved_name = new RegExp(
    '^(errorRecv|injectRecv|injectSend)$'
);

//
// Set up everything so the Elm app can use the websocket in the right way
//
export function handleWebsocket(url, app) {
    ws_url = url;

    // How to send global errors to the app
    errorRecv = app.ports.errorRecv;
    if (!errorRecv) {
        console.log('errorRecv not subscribed to - please fix that!');
    }

    // Provide a handy means to loop back messages
    if (app.ports.injectSend && app.ports.injectRecv) {
        app.ports.injectSend.subscribe(err =>
            app.ports.injectRecv.send(err));
    }

    // Create any channels that the app uses
    for (const port_name in app.ports) {
        if (port_name.length < 5 || reserved_name.test(port_name)) {
            continue;
        }
        const port = app.ports[port_name];
        const channel = camel_to_snake(port_name);

        if (port_name.endsWith('Send')) {
            // How the app sends a message
            port.subscribe(msg => {
                msg.channel = channel;
                if (msg.id == -1) {
                    msg.id = seq_num++;
                    wanted_seq_num[channel] = msg.id;
                }
                ws.send(JSON.stringify(msg));
            });
        } else if (port_name.endsWith('Recv')) {
            // How the app subscribes to notifications
            channels[channel] = port;
        } else if (port_name.endsWith('IsUp')) {
            // How the app subscribes to up/down state
            isup_ports.push(port);
            if (ws_up) {
                port.send(true);
            }
        }
    }

    // Kick off the first websocket connection
    retry_connection();
}

// fooBarBazSend -> foo_bar_baz
function camel_to_snake(name) {
    return name.slice(0, -4)
        .split(/(?=[A-Z])/)
        .join('_')
        .toLowerCase();
}

//
// Handle a new WebSocket (including creating it)
//
function init_ws() {
    // Handle incoming websocket notifications
    ws.onmessage = nfn => {
        const data = JSON.parse(nfn.data);
        const channel = data.channel;
        if (channel === undefined) {
            // The notification doesn't specify a channel - bad server!
            error(`Dropping notification without any channel: ${JSON.stringify(nfn)}`);
            console.log(nfn, nfn.data);
        } else if (channel == 'error') {
            // Fast-track the error string to the special error subscription.
            console.log('Raising error', data);
            errorRecv.send(data.value);
        } else {
            const port = channels[channel];
            if (port === undefined) {
                // Nobody is listening on this channel. Life can be harsh.
                error(`Dropping notification for unused channel ${channel}`);
                console.log(nfn, channels, data);
            } else {
                // Do any sequence number processing
                const wanted = wanted_seq_num[channel];
                if (wanted) {
                    if (data.id == wanted) {
                        // Match!
                        delete wanted_seq_num[channel];
                        port.send(data);
                    } else {
                        // Fail! Just log to console
                        console.log(`Dropping message for channel ${channel} since ` +
                            `wanted sequence numer ${wanted} but found ${data.id}`,
                            data);
                    }
                } else {
                    // No sequence number processing required
                    port.send(data);
                }
            }
        }
    };

    // Yay! We're up.
    ws.onopen = () => set_ws_state(true);

    // Boo! We're down.
    ws.onclose = reason => {
        // console.log('Websocket closed', reason);
        if (ws_up) {
            set_ws_state(false);
            // In Firefox (but not Chrome or Safari), the websocket close event
            // can arrive so quickly that, for example, a browser refresh causes
            // two websocket connection requests (one as a dying gasp from the
            // old code, then another from the new code). This seems to happen
            // within a window of 10ms or so. So for Firefox's benefit, wait for
            // 100ms before reconnecting.
            setTimeout(() => {
                console.log('Reconnecting to websocket');
                retry_connection();
            }, 100);
        }
    };

    // This is always boring
    // ws.onerror = err => console.log('WebSocket error', err);
}

// Update our notion of the websocket's state
function set_ws_state(state) {
    //console.log(`WebsocketIsUp is ${state}`, isup_ports);
    ws_up = state;
    for (const port of isup_ports) {
        port.send(state);
    }
}

// Try to connect to the server.
// Exponential backoff shouldn't be a win for the EnTrance
// use cases, so simply always try reconnecting after two seconds.
function retry_connection() {
    ws = new WebSocket(ws_url);
    init_ws();
    setTimeout(() => {
        if (ws.readyState != 1) {
            ws.close();
            retry_connection();
        }
    }, 2000);
}

// Raise an error - should only really be during development, when the
// developer has done something wrong.
function error(msg) {
    console.log(msg);
    errorRecv.send(msg);
}
