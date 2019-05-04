module Connection.Misc exposing
    ( decodeConnPrefs
    , encodeConnPrefs
    , setConnPrefs
    , toToast
    )

import Connection.Types exposing (..)
import EnTrance.Feature.Target.Connection as Con
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Utils.Toast exposing (Toast(..))


{-| Render a connection state to a toast.
-}
toToast : Con.State -> Toast
toToast state =
    case state of
        Con.Disconnected ->
            Success "Disconnected" ""

        Con.Connected ->
            Success "Connected" ""

        Con.FailureWhileDisconnecting why ->
            Danger "Failure while disconnecting" why

        Con.Finalizing ->
            Info "Finalizing connection setup..." ""

        Con.Connecting ->
            Info "Connecting..." ""

        Con.Disconnecting ->
            Info "Disconnecting..." ""

        Con.ReconnectingAfterFailure why ->
            Danger "Reconnecting after failure..." why

        Con.FailedToConnect why ->
            Danger "Failed to connect" why


setConnPrefs : Model -> ConnPrefs -> Model
setConnPrefs model prefs =
    let
        connection =
            model.connection
    in
    { model | connection = { connection | prefs = prefs } }



-- Encoder/decoder for `ConnPrefs`


encodeConnPrefs : ConnPrefs -> Encode.Value
encodeConnPrefs { params, autoConnect } =
    Encode.object
        [ ( "params", Con.encodeParams params )
        , ( "auto_connect", Encode.bool autoConnect )
        ]


decodeConnPrefs : Decoder ConnPrefs
decodeConnPrefs =
    Decode.map2 ConnPrefs
        (Decode.field "params" Con.decodeParams)
        (Decode.field "auto_connect" Decode.bool)
