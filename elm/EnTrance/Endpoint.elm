module EnTrance.Endpoint
    exposing
        ( RpcData(..)
        , isLoading
        , isFailure
        , Endpoint
        , getWebSocket
        , default
        , named
        , defaultEndpoint
        , loading
        , Params
        , request
        , setTarget
        , addString
        , addBool
        , addValue
        , Model
        , send
        , sendRaw
        , decodeRpc
        , forceRestart
        )

{-| Helper functionality for EnTrance endpoints. In particular:

 - all outbound requests include an `endpoint` string field, that is reflected
   back by the server in reply notifications, to identify the receiving sub-app

 - most outbound requests include an `id` string field, that is unique per
   endpoint and reflected back by the server

 - a subset of requests is considered an `rpc` by the client, meaning the client
   expects exactly one response notification indicating either success or error,
   the client validates the "id" field is the one it is waiting for, and the
   client maintains the state of whether it is waiting for a response (typically
   with some UI such as a progress bar)

## RpcData

One mental model is that one `RpcData` value corresponds to one progress indicator in
your view. ie an `RpcData` value encapsulates the state for a single synchronous
RPC request. If you can have three progress indicators visible (ie three indpendent rpc
requests at the same time, that can complete and each either succeed or fail) then
you want three `RpcData` values in your model.

@docs RpcData
@docs isLoading
@docs isFailure

## Endpoints

An `Endpoint` encapsulates the state for sending messages to the server, and
routing any resulting notifications back to this part of your app. You almost
certainly want exactly one `Endpoint` value in your model.

@docs Endpoint
@docs getWebSocket
@docs default
@docs named
@docs defaultEndpoint

## Endpoint-RpcData interactions

When you kick off an rpc request, you want the progress indicator to start showing.
Under the covers, this means putting the corresponding `RpcData` value into `Loading`
state, but also holding the correct message id value, so that only replies to that
particular request move it into `Success` or `Failure` state (vs, eg, a late reply
to a long-running cancelled prior operation). The `loading` function is what you
want to do that.

@docs loading

## Sending requests

The following functions make it easy to construct a request, and send it.

@docs Params
@docs request
@docs setTarget
@docs addString
@docs addBool
@docs addValue
@docs Model
@docs send
@docs sendRaw
@docs decodeRpc

## Built-in global requests

Type-safe constructors for any global requests not handled by a specific
module (such as `Ping` or `Persist` are here. There's currently only one.

@docs forceRestart
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import WebSocket
import EnTrance.Internal exposing (..)


{-| RpcData - a variation on Kris Jenkins'
[RemoteData](http://package.elm-lang.org/packages/krisajenkins/remotedata/latest/RemoteData#RemoteData)
that includes a string id during the Loading phase, that is used to  validate
reply notifications. It also requires error messages to have String type.
-}
type RpcData result
    = NotAsked
    | Loading String
    | Success result
    | Failure String


{-| Predicate that checks if the value is in `Loading` state.
(Same as `isLoading` for RemoteData.)
-}
isLoading : RpcData r -> Bool
isLoading rpcData =
    case rpcData of
        Loading _ ->
            True

        _ ->
            False


{-| Predicate that checks if the value is in `Failure` state.
(Same as isFailure for RemoteData.)
-}
isFailure : RpcData r -> Bool
isFailure rpcData =
    case rpcData of
        Failure _ ->
            True

        _ ->
            False


{-| Endpoint opaque type - everything needed to communicate to the server.
Use either [simple](#simple) or [named](#named) to create a value of this type.
-}
type Endpoint
    = Endpoint
        { endpoint : String
        , websocket : String
        , id : Int
        }


{-| Retrieve the websocket from an Endpoint
-}
getWebSocket : Endpoint -> String
getWebSocket (Endpoint e) =
    e.websocket


{-| Initialize an endpoint value using `defaultEndpoint` axs the name.
Use this when your app does not use multiple endpoints. Takes a websocket to use.
-}
default : String -> Endpoint
default =
    named defaultEndpoint


{-| Endpoint name to use if you don't need multiple endpoints. Works with `default`.
-}
defaultEndpoint : String
defaultEndpoint =
    "defaultEndpoint"


{-| Initialize an endpoint value, using an explicit endpoint name. Use
this when your app has multiple endpoints.

Arguments:

 - The endpoint name
 - The websocket to use
-}
named : String -> String -> Endpoint
named endpoint websocket =
    Endpoint { endpoint = endpoint, websocket = websocket, id = 0 }


{-| A 'Model' is an alias for a type that includes a single Endpoint entity.
This is used for the common sending functions because it makes life eaiser for callers.

(Note: this is exported simply so that we can document its type here. There is no
need for a caller ever to use this.)
-}
type alias Model model =
    { model
        | endpoint : Endpoint
    }



{- Internal : return the id field of an opaque Endpoint as a string -}


id2string : Endpoint -> String
id2string (Endpoint endpoint) =
    toString endpoint.id


{-| Return a "Loading" type, that indicates this endpoint awaits a
notification with an `id` matching the request created by the
next use of [send](#send).
-}
loading : Model model -> RpcData result
loading model =
    Loading (id2string model.endpoint)


{-| A set of request parameters (ie key-value pairs that get encoded into a request JSON request).
-}
type alias Params =
    List ( String, Encode.Value )


{-| Create a request Param value containing just a `req_type` parameter.
-}
request : String -> Params
request reqType =
    addString "req_type" reqType []


{-| Set the `target` request parameter.
-}
setTarget : String -> Params -> Params
setTarget =
    addString "target"


{-| Set an arbitrary 'String'-valued request parameter.
-}
addString : String -> String -> Params -> Params
addString key value =
    addValue key (Encode.string value)


{-| Set an arbitrary 'Bool'-valued request parameter.
-}
addBool : String -> Bool -> Params -> Params
addBool key value =
    addValue key (Encode.bool value)


{-| Set an arbitrary 'Encode.Value' request parameter.
-}
addValue : String -> Encode.Value -> Params -> Params
addValue key value otherParams =
    ( key, value ) :: otherParams


{-| Send an outbound RPC request, and update the id ready for the next one.
-}
send : Model m -> Params -> ( Model m, Cmd msg )
send model params =
    let
        allParams =
            ( "id", Encode.string (id2string model.endpoint) ) :: params

        incr (Endpoint endpoint) =
            Endpoint { endpoint | id = endpoint.id + 1 }
    in
        ( { model | endpoint = incr model.endpoint }
        , sendRaw model.endpoint allParams
        )


{-| Send a minimal EnTrance request over the specified websocket, without doing
anything about ids. You almost certainly want to use [send](#send) instead of this.
-}
sendRaw : Endpoint -> Params -> Cmd msg
sendRaw (Endpoint { endpoint, websocket }) params =
    let
        allParams =
            ( "endpoint", Encode.string endpoint ) :: params
    in
        Encode.object allParams
            |> Encode.encode 0
            |> WebSocket.send websocket


{-| Decode an incoming notification that is an RPC reply. If the
notification has a stale or incorrect `id` value, it triggers a
decode error. (You can disambiguate genuine decode errors from this
bad `id` value using the [errorIsWarning](#errorIsWarning) function.)
-}
decodeRpc : Decoder result -> RpcData result -> Decoder (RpcData result)
decodeRpc decoder rpcData =
    case rpcData of
        Loading id ->
            Decode.field "id" Decode.string
                |> Decode.andThen (checkId id decoder)

        _ ->
            {- If the RpcData isn't Loading, then we assume some sort of race
               condition has occurred, as the flip-side of an id mismatch. For
               example, suppose we send (req1, req2, req3) in order, but get
               (nfn2, nfn3, nfn1) in response. Then we will discard nfn2 because
               the id is out of date (see checkId below), accept nfn3 and move
               to Success or Failure state, and then handle nfn1 here. It's the
               same thing as an out-of-order response, so treat it the same -
               yield a special decoder error that will result in just a warning
               log, not a big error suggesting an actual bug.
            -}
            Decode.fail <|
                dropPrefix
                    ++ "no reply notification since state is"
                    ++ toString rpcData
                    ++ " (not Loading)"



{- Internal: check the id field of the RPC reply -}


checkId : String -> Decoder result -> String -> Decoder (RpcData result)
checkId expectedId decoder decodedId =
    if decodedId /= expectedId then
        {- Some sort of out-of-order reply has occurred - we're now waiting for
           a different (should always be later) id, so this is a stale reply
           to an old request we no longer care about. So return a special
           decoder error that results in a log, not a major error notification.
        -}
        Decode.fail <|
            dropPrefix
                ++ expectedId
                ++ " but received "
                ++ decodedId
                ++ ")"
    else
        {- This is the reply we're expecting, so it must be either a succeess or
           failure notification
        -}
        Decode.oneOf
            [ Decode.field "result" decoder
                |> Decode.map Success
            , Decode.field "error" Decode.string
                |> Decode.map Failure
            ]


{-| Restart the server (assuming it's running in a harness where
exiting with the right code causes a re-spawn by a supervisor function).
Use with caution.
-}
forceRestart : Endpoint -> Cmd msg
forceRestart endpoint =
    request "force_restart"
        |> sendRaw endpoint
