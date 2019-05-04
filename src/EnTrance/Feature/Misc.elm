module EnTrance.Feature.Misc exposing
    ( forceRestart
    , ping
    , decodePong
    )

{-| This module contains a grab-bag of type-safe wrappers around bits of
EnTrance functionality that don't obviously fit somewhere better.


# Raising errors

It's possible to raise a global error (as caught by the `errorSub`
subscription) from anywhere. This can be a convenient way to correctly handle
rare failure cases without lots of manual plumbing. If you want to do this,
then declare a port once in your application like this:

    port raiseError : String -> Cmd msg


# Server-level interactions

@docs forceRestart
@docs ping
@docs decodePong

-}

import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)


{-| It's possible to request the server to restart itself, in some
circumstances:

  - it's running in a harness where exiting with the right code
    causes a re-spawn by a supervisor function

  - it's configured to permit this (via the `allow_restart_requests`
    configuration option - see `cfg_core.py`).

Obviously this affects all clients, not just the one making the request, so use
with caution.

-}
forceRestart : Request
forceRestart =
    Request.new "force_restart"


{-| Send a request to the server, that elicits a response with notification
type "pong". This can be used with either RPC or simple async semantics.

In practice this is of limited usefulness, since the server can be alive and
connected. In most cases it's best to use the `channelIsUp` notifications
(indicating basic websocket connectivity state) for major UI liveness
indications (eg disabling all buttons) and then use
[RpcData](EnTrance-Channel#RpcData) state to indicate if a particular feature
is being slow.

-}
ping : Request
ping =
    Request.new "ping"


{-| Decode a `pong` notification
-}
decodePong : msg -> Decoder msg
decodePong msg =
    Gen.decodeNfn "pong" (Decode.succeed msg)
