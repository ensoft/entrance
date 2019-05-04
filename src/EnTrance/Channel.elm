module EnTrance.Channel exposing
    ( SendPort
    , RecvPort
    , IsUpPort
    , sendSimpleRpc
    , sendRpc
    , send
    , sendRpcCmd
    , sendRpcCmds
    , sendCmd
    , sendCmds
    , sub
    , ErrorRecvPort
    , InjectSendPort
    , InjectRecvPort
    )

{-| EnTrance clients talk to a server over a single websocket. A "channel" is
like a tunnel inside that websocket, dedicated to one part of your Elm
application.

Simple apps need only a single channel. The value comes when your app becomes
more complex, and gains more modular structure. Often you end up with several
different "sub-apps", each of which has responsibility for some part of the
overall user experience. In such cases, it's easiest to create one channel per
sub-app, so that each sub-app has its own two-way communciation mechanism
with the features it invokes on the server, without coupling it to the other
sub-apps.

You should never need more than one channel in a given module. If you're
thinking about that, you probably want multiple
[RpcData](EnTrance-Types#RpcData) values in your model instead.


# How to use

Looking at some of the sample apps, eg the [notes
app](https://github.com/ensoft/entrance/samples/1_notes/elm/src/State.elm) may
be a helpful supplement to the description here.


## Channels and ports

A channel is created via either two or three ports in an Elm module. The
two-port case looks like this:

    import EnTrance.Channel as Channel

    port myAppSend : Channel.SendPort msg

    port myAppRecv : Channel.RecvPort msg

This creates a send/receive port pair, implementing one channel, called
"myApp". You can choose almost anything you like for the "myApp" bit.

This is a bit weird and magical, based on the names of the ports:

  - the "Send" suffix tells EnTrance that `myAppSend` is used for sending messages

  - the "myApp" prefix is used to add a `"channel": "my_app"` field to any
    messages send to the server via that port

  - the server reflects this `"channel": "my_app"` back in any replies

  - these get routed back to the `myAppRecv` port based on the "myApp" prefix
    and "Recv" suffix

So you can choose any channel name you like ("myApp" in this case), but:

  - you have to apply that name consistently across all the ports making up the
    channel ("myAppSend" and "myAppRecv" in this case)

  - if you have more than one channel in your app, they must have unique names

  - you can't use "error" or "inject" for the channel name, since these are
    taken (see below)

The three-port case is where you also specify a third port:

    port myAppIsUp : Channel.IsUpPort msg

This gives you up/down notifications for the channel state, ie whether there is
a server on the end of it. If you have a `Msg` constructor like this:

    type Msg = ...
             | AppIsUp Bool

and instantiate an `IsUpPort`:

    port myAppIsUp : Channel.IsUpPort msg

then you can just subscribe to `myAppIsUp AppIsUp` and you'll receive an
`AppIsUp` message whenever the connection state changes.

@docs SendPort
@docs RecvPort
@docs IsUpPort


## Sending messages to the server

You typically send an RPC message to the server using
[sendSimpleRpc](#sendSimpleRpc), [sendRpc](#sendRpc) or [send](#send). The key
distinction between these three options is:

  - `sendSimpleRpc` is the easiest way to send an RPC

  - `sendRpc` allows multiple simultanous independent RPCs, but it's up to you to
    set the right [RpcData](EnTrance-Types#RpcData) to `Loading`.

  - `send` is for async (fire-and-forget) outbound messages.

@docs sendSimpleRpc
@docs sendRpc
@docs send

If you want more low-level control, you can create just a raw `Cmd` for either
RPC or async requests using the following functions.

@docs sendRpcCmd
@docs sendRpcCmds
@docs sendCmd
@docs sendCmds


## Receiving notifications from the server

In order to receive notifications from the server (such as RPC replies), use
[sub](#sub) to subscribe to notifications you receive on this channel. The
notification arrives in JSON format, so you need to supply a set of candidate
JSON decoders, that turn any expected JSON notification into a `Msg` for your
`update` function.

For example, suppose you are using the built-in Syslog and Netconf features, so
expect to receive one of those two notifications on the "myApp" channel. Just
create `Msg` constructors for those two options:

    type Msg
        = ...
        | GotSyslog Syslog
        | GotNetconfResult String
        | Error String

Then the 'sub' function turns the type-safe decoder for each feature
([Syslog.decode](EnTrance-Feature-Target-Syslog#decode) and
[Netconf.decodeRequest](EnTrance-Feature-Target-Netconf#decodeRequest)) into a
subscription like this:

    Channel.sub myAppRecv
        Error
        [ Syslog.decode GotSyslog
        , Netconf.decodeResult GotNetconfResult
        ]

Such a subscription means that whenever you receive an incoming notification on
the channel, either:

  - one of your decoders will succeed, and you'll receive a `GotSyslog` or
    `GotNetconfResult` message

  - you'll receive an `Error` message with a string explaining what went wrong in
    the decoding process

@docs sub


## Error and inject pseudo-channels

There are two "magic" channels, that can be instantiated only once in your
application. These consume the channel names "error" and "inject".


### The error pseudo-channel

You should instantiate exactly one "error" receive port in your application,
and handle the (rare) errors signalled there:

    port errorRecv : Channel.ErrorRecvPort

This is used to signal unexpected errors that can't be associated with a
particular operation, such as the server complaining it can't decode valid JSON
out of a request it received.

@docs ErrorRecvPort


### The inject pseudo-channel

Finally, you can optionally create a pair of send/receive channels with the
magic name `inject`, and special types:

    port injectSend : Channel.InjectSendPort

    port injectRecv : Channel.InjectRecvPort

These "loop round", so a JSON message send out on `injectSend` is received on
`injectRecv`. This can provide a handy way for complex apps to feed messages
from sub-apps back to the top level in a clean way. (You can do it lots of
other ways if you prefer.) For an example of how to use it, see the [example
code](https://github.com/ensoft/entrance/samples/4_router_simple/elm/src/Utils/Inject.elm).

@docs InjectSendPort
@docs InjectRecvPort

-}

import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (RpcData)
import Json.Decode as Decode exposing (Decoder, decodeValue)
import Json.Encode as Json
import RemoteData exposing (RemoteData(..))


{-| A port to send messages over a channel to the server.
-}
type alias SendPort msg =
    Json.Value -> Cmd msg


{-| A port to receive notifications over a channel from the server.
-}
type alias RecvPort msg =
    (Json.Value -> msg) -> Sub msg


{-| A port from which to be notified of channel up/down status.
-}
type alias IsUpPort msg =
    (Bool -> msg) -> Sub msg


{-| A port from which to be notified of global errors of type `String`. You
should have exactly one of these in your application, named `errorPort`.
-}
type alias ErrorRecvPort msg =
    (String -> msg) -> Sub msg


{-| A port to inject a JSON value out of. You can have one of these in your
application if you want, called `injectSend`.
-}
type alias InjectSendPort msg =
    Json.Value -> Cmd msg


{-| A port to subcribe to, for injected JSON values. You can have one of these
in your application if you want to, named `injectRecv`.
-}
type alias InjectRecvPort msg =
    (Json.Value -> msg) -> Sub msg


{-| Send an RPC request. If you're just starting out,
[sendSimpleRpc](#sendSimpleRpc) may be easier. If you need more control, use
[sendRpcCmd](#sendRpcCmd).

Updating the relevant [RpcData](#RpcData) to state `Loading` is your
responsibility.

This assumes your model includes a field called `sendPort` of type [SendPort
msg](#SendPort).

-}
sendRpc :
    { model | sendPort : SendPort msg }
    -> Request
    -> ( { model | sendPort : SendPort msg }, Cmd msg )
sendRpc model request =
    ( model, sendRpcCmd model.sendPort request )


{-| Simplified variant of [sendRpc](#sendRpc) that assumes the relevant
[RpcData](#RpcData) in your model is called `result`, and sets the state to
`Loading` for you.

This assumes your model includes a field called `sendPort` of type [SendPort
msg](#SendPort).

-}
sendSimpleRpc :
    { model | result : RpcData result, sendPort : SendPort msg }
    -> Request
    -> ( { model | result : RpcData result, sendPort : SendPort msg }, Cmd msg )
sendSimpleRpc model request =
    ( { model | result = Loading }, sendRpcCmd model.sendPort request )


{-| Create a command to send a `Request` over a channel with RPC semantics (the
mainline case). In many cases, using [sendRpc](#sendRpc) is nicer than calling
this directly.

RPC semantics mean that exactly one reply notification is expected (either
success or error), and that a unique message identifier is used to ensure that
out-of-order replies don't get mistaken for the reply we're waiting for here.

    port appSend : SendPort cmd

    Request.new "some_message"
        |> Channel.sendRpcCmd appSend

-}
sendRpcCmd : SendPort msg -> Request -> Cmd msg
sendRpcCmd sendPort request =
    -- The `-1` value for `id` is a magic request for the websocket
    -- handler to automatically allocate a unique id, and check replies
    -- against that.
    request
        |> Request.addInt "id" -1
        |> sendCmd sendPort


{-| Handy way to send a list of requests in one shot.
-}
sendRpcCmds : SendPort msg -> List Request -> Cmd msg
sendRpcCmds sendPort requests =
    Cmd.batch (List.map (sendRpcCmd sendPort) requests)


{-| Simple way to send an async message. If you need more control, use
[sendCmd](#sendCmd).

This assumes your model includes a field called `sendPort` of type [SendPort
msg](#SendPort).

-}
send :
    { model | sendPort : SendPort msg }
    -> Request
    -> ( { model | sendPort : SendPort msg }, Cmd msg )
send model request =
    ( model, sendCmd model.sendPort request )


{-| Create a command to send a `Request` over a channel with async
(fire-and-forget) semantics.

    port appSend : SendPort msg

    Request.new "some_message"
        |> Channel.sendCmd myAppSend

-}
sendCmd : SendPort msg -> Request -> Cmd msg
sendCmd sendPort =
    sendPort << Request.encode


{-| Helper to send a list of async commands in one shot.
-}
sendCmds : SendPort msg -> List Request -> Cmd msg
sendCmds sendPort requests =
    Cmd.batch (List.map (sendCmd sendPort) requests)


{-| Subscribe to a receive port, and use the specified list of decoders to turn
JSON notifications for that channel into `Msg`s of your choice. Takes a receive
port, an error message constructor, and a list of individual notification
decoders.
-}
sub :
    RecvPort msg
    -> (String -> msg)
    -> List (Decoder msg)
    -> Sub msg
sub portSub errorMsg decoders =
    let
        decode value =
            case decodeValue (Decode.oneOf decoders) value of
                Ok msg ->
                    msg

                Err err ->
                    errorMsg ("JSON decode error: " ++ Decode.errorToString err)
    in
    portSub decode
