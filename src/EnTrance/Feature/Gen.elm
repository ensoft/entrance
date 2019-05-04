module EnTrance.Feature.Gen exposing
    ( start
    , stop
    , decodeRpc
    , decodeIsUp
    , decodeNfn
    )

{-| This module provides common functionality used for writing "client
libraries" (typesafe Elm wrappers for the JSON message formats that interact
with a particular server-side feature).

The functions here aren't for direct use by application code. Rather they're
useful if you're implementing a new feature, and are writing a typesafe wrapper
(akin to the `EnTrance.Feature.*` built-in examples).


## Feature lifecycle

Configured features are started unconditionally on the server. Any other
features must be requested by the client. These should be wrapped by your own
function specifying the feature name and any other required parameters.

@docs start
@docs stop


## Decoding common fields

The following functions decode common fields that aren't specific to your
feature. These should be wrapped by your own functions that also decode any
feature-specific fields.

@docs decodeRpc
@docs decodeIsUp
@docs decodeNfn

-}

import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (MaybeSubscribe(..), RpcData)
import Json.Decode as Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..))


{-| Create a `start_feature` request. See eg
[CLI.start](EnTrance-Feature-Target-CLI#start) for an example usage.

This is an async request - it should unconditionally succeed unless there is an
obvious programming error (eg a mis-spelled feature name) that will show up in
the server logs.

-}
start : String -> MaybeSubscribe -> Request
start feature subscribe =
    let
        bool =
            case subscribe of
                SubscribeToConState ->
                    True

                IgnoreConState ->
                    False
    in
    Request.new "start_feature"
        |> Request.addString "feature" feature
        |> Request.addBool "con_state_subscribe" bool


{-| Create a `stop_feature` request. See eg
[CLI.stop](EnTrance-Feature-Target-CLI#stop) for an example usage.

This is an async request - it should unconditionally succeed unless there is an
obvious programming error (eg a mis-spelled feature name) that will show up in
the server logs.

-}
stop : String -> Request
stop feature =
    Request.new "stop_feature"
        |> Request.addString "feature" feature


{-| Decode an RPC response of specified type, given a decoder for a success
value. See eg [CLI.decodeExec](EnTrance-Feature-Target-CLI#decodeExec) for an
example usage.
-}
decodeRpc : String -> Decoder a -> Decoder (RpcData a)
decodeRpc wantedType decodeSuccessValue =
    let
        decodeNext =
            Decode.oneOf
                [ Decode.field "result" decodeSuccessValue
                    |> Decode.map Success
                , Decode.field "error" Decode.string
                    |> Decode.map Failure
                ]
    in
    decodeNfn wantedType decodeNext


{-| Decode a notification requested using
[MaybeSubscribe](EnTrance-Types#MaybeSubscribe) for a given feature. See eg
[CLI.decodeIsUp](EnTrance-Feature-Target-CLI#decodeIsUp) for an example usage.
-}
decodeIsUp : String -> Decoder Bool
decodeIsUp desiredFeature =
    let
        resolve foundFeature state =
            if foundFeature == desiredFeature then
                Decode.succeed state

            else
                Decode.fail
                    ("Can't decode connection state for feature"
                        ++ foundFeature
                        ++ ", was expecting "
                        ++ desiredFeature
                    )
    in
    Decode.map2 resolve
        (Decode.field "feature" Decode.string)
        (Decode.field "state_is_up" Decode.bool)
        |> Decode.andThen identity


{-| Decode an arbitrary notification, given an expected `nfn_type` value and a
decoder for the payload. See eg
[Syslog.decode](EnTrance-Feature-Target-Syslog#decode) for an example usage.
-}
decodeNfn : String -> Decoder a -> Decoder a
decodeNfn wantedType decodeNext =
    let
        maybeDecodeNext foundType =
            if foundType == wantedType then
                decodeNext

            else
                Decode.fail ("Can't decode notification of type " ++ foundType)
    in
    Decode.field "nfn_type" Decode.string
        |> Decode.andThen maybeDecodeNext
