module EnTrance.Feature.Target.Netconf exposing
    ( get
    , getConfig
    , editConfig
    , validate
    , commit
    , Op(..)
    , request
    , decodeRequest
    , start
    , stop
    , decodeIsUp
    )

{-| Invoke Netconf operations.

This module presents two APIs, and you can pick whichever suits your app the best:

  - Standalone functions for each operation ([get](#get), [commit](#commit) etc)

  - A [data type](#Op) for all possible operations, and a [single
    function](#request) to invoke the specified operation.

Functionality is identical across these two API options. Also, the decoder for
reply notifications is [decodeRequest](#decodeRequest) either way.

Notifications are of type `netconf` and have a `String` success type.


## Standalone API

@docs get
@docs getConfig
@docs editConfig
@docs validate
@docs commit


## Data type API

@docs Op
@docs request
@docs decodeRequest


## Feature start/stop

@docs start
@docs stop
@docs decodeIsUp

-}

import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (MaybeSubscribe, RpcData)
import Json.Decode as Decode exposing (Decoder)


{-| Name of the feature
-}
netconf : String
netconf =
    "netconf"


{-| All possible Netconf operations.
-}
type Op
    = Get String
    | GetConfig String
    | EditConfig String
    | Validate
    | Commit


{-| Encode a Netconf Request
-}
request : Op -> Request
request op =
    let
        req opType =
            Request.new netconf
                |> Request.addString "op" opType

        reqWithValue opType value =
            req opType
                |> Request.addString "value" value
    in
    case op of
        Get value ->
            reqWithValue "get" value

        GetConfig value ->
            reqWithValue "get_config" value

        EditConfig value ->
            reqWithValue "edit_config" value

        Validate ->
            req "validate"

        Commit ->
            req "commit"


{-| Decode the reply from any Netconf operation. This always has `String` type,
but for some operations, the success/failure bit is really all that's being
communicated and the string will be empty. Takes a message constructor.
-}
decodeRequest : (RpcData String -> msg) -> Decoder msg
decodeRequest makeMsg =
    Gen.decodeRpc netconf Decode.string
        |> Decode.map makeMsg


{-| Standalone Netconf `get`
-}
get : String -> Request
get value =
    request (Get value)


{-| Standalone Netconf `get config`
-}
getConfig : String -> Request
getConfig value =
    request (GetConfig value)


{-| Standalone Netconf `edit config`
-}
editConfig : String -> Request
editConfig value =
    request (EditConfig value)


{-| Standalone Netconf `validate`
-}
validate : Request
validate =
    request Validate


{-| Standalone Netconf `commit`
-}
commit : Request
commit =
    request Commit


{-| Start a Netconf feature instance. This represents the option to connect to
one router. This is an async request - use the connection state notifications
to track progress.
-}
start : MaybeSubscribe -> Request
start =
    Gen.start netconf


{-| Stop a Netconf feature instance. This is an async request.
-}
stop : Request
stop =
    Gen.stop netconf


{-| Decode an up/down notification requested by passing
[SubscribeToConState](EnTrance-Types#MaybeSubscribe) to
[start](#start). Takes a message constructor.
-}
decodeIsUp : (Bool -> msg) -> Decoder msg
decodeIsUp makeMsg =
    Gen.decodeIsUp netconf
        |> Decode.map makeMsg
