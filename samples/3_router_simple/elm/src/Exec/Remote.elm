module Exec.Remote exposing (endpoint, nfnDecoder, sendReq)

{-|
   Remote handling for the CLI config feature
-}

import Json.Decode as Decode exposing (Decoder)
import EnTrance.Endpoint as Endpoint
import EnTrance.Feature as Feature
import Exec.Types exposing (..)


{-| The endpoint name
-}
endpoint : String
endpoint =
    "exec"



{- The server feature name we want to start and monitor -}


feature : String
feature =
    "cli_exec"



{-
   Decode incoming JSON notifications
-}


nfnDecoder : Model -> String -> Decoder Notification
nfnDecoder model nfnType =
    let
        rpcReply =
            Endpoint.decodeRpc Decode.string
    in
        case nfnType of
            "cli_exec" ->
                rpcReply model.result
                    |> Decode.map CLIExecNfn

            "connection_state" ->
                Feature.decodeConnectionState feature
                    |> Decode.map ConStateNfn

            unknown ->
                Decode.fail <| "Unknown exec nfn_type: " ++ unknown



{-
   Send outgoing JSON requests
-}


sendReq : Request -> Model -> ( Model, Cmd Msg )
sendReq req model =
    (case req of
        CLIExecReq cli ->
            Endpoint.request "cli_exec"
                |> Endpoint.addString "command" cli

        StartFeatureReq ->
            Feature.start feature Feature.SubscribeToConState
    )
        |> Endpoint.addDefaultTarget
        |> Endpoint.send model
