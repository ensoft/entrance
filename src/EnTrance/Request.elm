module EnTrance.Request exposing
    ( Request(..)
    , new
    , addBool
    , addInt
    , addInts
    , addString
    , addStrings
    , addValue
    , encode
    )

{-| A [Request](#Request) is a client-side representation of a request, that
can be manipulated client-side before actually serialising into a JSON message
and sending to the server. For example, this:

    import EnTrance.Request as Request

    Request.new "order_ice_cream"
    |> Request.addString "flavour" "chocolate"
    |> Request.addBool "with_flake" True

would end up as a JSON request to the server containing

    {
        "msg_type": "order_ice_cream",
        "flavour": "chocolate",
        "with_flake": true
    }

(Actually, it also adds a `"target": "defaultTarget"`, but you don't have to
care about this unless you're writing a particular type of complex app, in
which case you want to use [Target.set](EnTrance-Feature-Target#set) on most
requests yourself.)

In the typical case, you would finish with [sendRpcUsing](#sendRpcUsing):

    port myAppSend : Json.Encode.Value -> Cmd msg

    Request.new "order_ice_cream"
        |> Request.addString "flavour" "chocolate"
        |> Request.addBool "with_flake" True
        |> Request.sendRpcUsing myAppSend

where `myAppSend` is the [channel](EnTrance-Channel) you're sending over. This
invokes some extra magic, whereby the actual JSON going to the server would be
something like:

    {
        "msg_type": "order_ice_cream",
        "flavour": "chocolate",
        "with_flake": true,
        "channel": "my_app",
        "id": <some auto-generated unique identifier>
    }

so that the reply gets routed back to the `appRecv` channel (using the
`"channel": "my_app"` field that was added for you), and any out-of-order or outdated
replies get automatically dropped.

If you add multiple values for the same key, then the most recent value wins. For example:

    Request.new "order_ice_cream"
        |> Request.addString "flavour" "chocolate"
        |> Request.addString "flavour" "strawberry"
        |> Request.encode

yields:

    {
        "msg_type": "order_ice_cream",
        "flavour": "strawberry"
    }


# Request type

@docs Request


# Constructing a Request

@docs new
@docs addBool
@docs addInt
@docs addInts
@docs addString
@docs addStrings
@docs addValue


# Using a Request

The most common use of a Request is calling something like
[Channel.sendRpc](EnTrance-Channel#sendRpc) with it. But you can also just
encode it as JSON if you like.

@docs encode

-}

import Dict exposing (Dict)
import Json.Encode as Encode


{-| A request value, that can be built up client-side, before eventually being
sent over a channel to the server (typically using `send` from
`EnTrance.Endpoint`).
-}
type Request
    = Request (Dict String Encode.Value)


{-| Create a request Param value containing just a `req_type` parameter.

(Actually it also creates a default `target` value, but you don't have to care.
See [Target](EnTrance-Feature-Target) if interested.)

-}
new : String -> Request
new reqType =
    Request Dict.empty
        |> addString "req_type" reqType
        |> addString "target" "defaultTarget"


{-| Add a 'Bool'-valued parameter to a request.
-}
addBool : String -> Bool -> Request -> Request
addBool key value =
    addValue key (Encode.bool value)


{-| Add an 'Int'-valued parameter to a request.
-}
addInt : String -> Int -> Request -> Request
addInt key value =
    addValue key (Encode.int value)


{-| Add a 'List Int'-valued parameter to a request.
-}
addInts : String -> List Int -> Request -> Request
addInts key values =
    addValue key (Encode.list Encode.int values)


{-| Add a 'String'-valued parameter to a request.
-}
addString : String -> String -> Request -> Request
addString key value =
    addValue key (Encode.string value)


{-| Add a 'List String'-valued parameter to a request.
-}
addStrings : String -> List String -> Request -> Request
addStrings key values =
    addValue key (Encode.list Encode.string values)


{-| Add an arbitrary 'Encode.Value' parameter to a request
-}
addValue : String -> Encode.Value -> Request -> Request
addValue key value (Request otherParams) =
    Request (Dict.insert key value otherParams)


{-| Encode a 'Request' into a JSON value.
-}
encode : Request -> Encode.Value
encode (Request args) =
    Encode.object (Dict.toList args)
