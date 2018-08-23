module EnTrance.Notification
    exposing
        ( GlobalNfn(..)
        , Config
        , decode
        , delegateTo
        , subscription
        )

{-| Handle notifications from the server.

@docs GlobalNfn
@docs Config
@docs decode
@docs delegateTo
@docs subscription
-}

import Dict as Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import WebSocket
import EnTrance.Internal exposing (..)


{-| The top-level notification types
-}
type GlobalNfn
    = WebSocketUpNfn
    | PongNfn
    | ErrorNfn String
    | WarningNfn String


{-| Configure your endpoints. This value specifies how to handle 'GlobalNfn'
notifications (ie which message constructor to use) and also takes a 'Dict'
mapping endpoint names to handlers. So if your app is simple, just provide a
single default additional endpoint. If your app has four endpoints, then
name them here and specify where you want to handle their notifications.
-}
type alias Config model nfn =
    { makeGlobal : GlobalNfn -> nfn
    , endpoints : Dict String (String -> model -> Decoder nfn)
    }


{-| Subscribe to websocket notifications. Takes a websocket and a message constructor.
-}
subscription : (String -> msg) -> String -> Sub msg
subscription mkMsg websocket =
    WebSocket.listen websocket mkMsg


{-| Decode a notification.
-}
decode : Config model nfn -> model -> String -> nfn
decode cfg model json =
    case Decode.decodeString (nfnDecoder cfg model) json of
        Ok decoded_nfn ->
            decoded_nfn

        Err error ->
            if errorIsWarning error then
                cfg.makeGlobal (WarningNfn error)
            else
                (cfg.makeGlobal << ErrorNfn) ("Invalid JSON: " ++ toString error)


{-| Helper function to delegate a notification to a sub-part of the main app
-}
delegateTo :
    (subModel -> nfnType -> Decoder subNfn)
    -> (model -> subModel)
    -> (subNfn -> nfn)
    -> nfnType
    -> model
    -> Decode.Decoder nfn
delegateTo decoder subModel nfnCons nfnType model =
    decoder (subModel model) nfnType
        |> Decode.map nfnCons



{-
   Then do the first part of decoding: find the endpoint and notification type
-}


nfnDecoder : Config model nfn -> model -> Decode.Decoder nfn
nfnDecoder cfg model =
    Decode.map2 (,)
        (Decode.field "endpoint" Decode.string)
        (Decode.field "nfn_type" Decode.string)
        |> Decode.andThen (nfnEndpointDecoder cfg model)



{-
   Then use that data to demux out to the appropriate endpoint
-}


nfnEndpointDecoder : Config model nfn -> model -> ( String, String ) -> Decoder nfn
nfnEndpointDecoder cfg model ( endpoint, nfnType ) =
    if endpoint == globalEndpointName then
        globalNfnDecoder nfnType
            |> Decode.map cfg.makeGlobal
    else
        case Dict.get endpoint cfg.endpoints of
            Just decoder ->
                decoder nfnType model

            Nothing ->
                Decode.fail <| "Unknown endpoint: " ++ endpoint



{-
   Handle incoming messsages with the "global" endpoint, that can't be
   dispatched somewhere else
-}


globalNfnDecoder : String -> Decode.Decoder GlobalNfn
globalNfnDecoder nfnType =
    case nfnType of
        "websocket_up" ->
            Decode.succeed WebSocketUpNfn

        "pong" ->
            Decode.succeed PongNfn

        "error" ->
            Decode.field "value" Decode.string
                |> Decode.map ErrorNfn

        unknown ->
            Decode.fail <| "Unknown global nfn_type: " ++ unknown
