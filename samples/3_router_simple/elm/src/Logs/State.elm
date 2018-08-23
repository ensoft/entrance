module Logs.State exposing (..)

{-|
   State handling for logs feature
-}

import Response exposing (withCmd)
import Utils.Extra.Response exposing (pure)
import EnTrance.Endpoint as Endpoint
import Utils.LoL as LoL exposing (LoL)
import Utils.Inject as Inject
import Utils.Toast as Toast
import Logs.Remote exposing (..)
import Logs.Types exposing (..)
import TopLevel.Types as TopLevel


{-
   Initial state
-}


empty : LoL a
empty =
    LoL.empty 1.0


initialModel : String -> Model
initialModel websocket =
    { logs = empty
    , endpoint = Endpoint.named endpoint websocket
    }



{-
   When we are connected with the server, start monitoring syslogs
-}


websocketUp : Model -> ( Model, Cmd Msg )
websocketUp model =
    -- Just start a plain old syslog feature, with no additional debugs or filters
    startSyslogFeature model [] []



{-
   Updates - none right now, but leave a placeholder in case this module
   gets extended
-}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        None ->
            pure model



{-
   Handle inbound notification from the server
-}


nfnUpdate : Notification -> Model -> ( ( Model, Cmd Msg ), Cmd TopLevel.Msg )
nfnUpdate nfn model =
    case nfn of
        LogNfn logMsg time ->
            let
                maybeToast =
                    if String.contains "%MGBL-CONFIG-6-DB_COMMIT : " logMsg then
                        withCmd (Inject.toast <| Toast.Info "New configuration commit point" "")
                    else
                        pure
            in
                pure { model | logs = LoL.add logMsg time model.logs }
                    |> maybeToast



{-
   User clicked the "Clear" button
-}


clearAll : Model -> Model
clearAll model =
    { model | logs = empty }
