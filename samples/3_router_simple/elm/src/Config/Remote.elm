module Config.Remote exposing (endpoint, nfnDecoder, sendReq)

{-|
   Remote handling for the CLI config feature
-}

import Dict
import Json.Decode as Decode exposing (Decoder)
import EnTrance.Endpoint as Endpoint exposing (RpcData(..))
import EnTrance.Feature as Feature
import EnTrance.Persist as Persist
import Config.Types exposing (..)
import Utils.Extra.Json.Encode as Encode


{-| The endpoint name
-}
endpoint : String
endpoint =
    "config"



{- The server feature name we want to start and monitor -}


feature : String
feature =
    "cli_config"



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
            "cli_config_load" ->
                rpcReply model.commitResult
                    |> Decode.map ConfigLoadNfn

            "cli_config_commit" ->
                rpcReply model.commitResult
                    |> Decode.map ConfigCommitNfn

            "cli_config_get_failures" ->
                rpcReply model.failuresResult
                    |> Decode.map ConfigGetFailuresNfn

            "persist_load" ->
                Persist.decode (Decode.dict Decode.string)
                    |> Decode.map PersistLoadNfn

            "connection_state" ->
                Feature.decodeConnectionState feature
                    |> Decode.map ConStateNfn

            unknown ->
                Decode.fail <| "Unknown commit nfn_type: " ++ unknown



{-
   Send outgoing JSON requests
-}


sendReq : Request -> Model -> ( Model, Cmd Msg )
sendReq req model =
    (case req of
        ConfigLoadReq config ->
            Endpoint.request "cli_config_load"
                |> Endpoint.addString "config" config

        ConfigCommitReq checkOnly ->
            Endpoint.request "cli_config_commit"
                |> Endpoint.addBool "check_only" checkOnly

        ConfigGetFailuresReq ->
            Endpoint.request "cli_config_get_failures"

        PersistSaveReq data ->
            Persist.save (Encode.dict data)

        PersistLoadReq ->
            Persist.load (Encode.dict Dict.empty)

        StartFeatureReq ->
            Feature.start feature Feature.SubscribeToConState
    )
        |> Endpoint.addDefaultTarget
        |> Endpoint.send model
