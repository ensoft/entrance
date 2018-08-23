module Exec.State exposing (..)

{-|
   State handling for CLI exec sub-app
-}

import Utils.Extra.Response exposing (pure)
import EnTrance.Endpoint as Endpoint exposing (RpcData(..))
import Exec.Remote exposing (..)
import Exec.Types exposing (..)


{- Initial state -}


initialModel : String -> Model
initialModel websocket =
    { cli = ""
    , result = NotAsked
    , connectionUp = False
    , endpoint = Endpoint.named endpoint websocket
    }



{- When we reach the server, start the cli_exec feature -}


websocketUp : Model -> ( Model, Cmd Msg )
websocketUp model =
    sendReq StartFeatureReq model



{- Updates -}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ExecMsg ->
            sendReq (CLIExecReq model.cli) { model | result = Endpoint.loading model }

        UpdateCLIMsg cli ->
            pure { model | cli = cli }



{- Handle notification inbound from the server -}


nfnUpdate : Notification -> Model -> ( Model, Cmd Msg )
nfnUpdate nfn model =
    case nfn of
        CLIExecNfn result ->
            pure { model | result = result }

        ConStateNfn connectionUp ->
            pure { model | connectionUp = connectionUp }



{- User clicked the "Clear" button -}


clearAll : Model -> Model
clearAll model =
    { model | cli = "", result = NotAsked }
