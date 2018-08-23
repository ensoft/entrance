module Netconf.Remote exposing (endpoint, nfnDecoder, sendReq)

{-|
   Remote handling for the Netconf feature
-}

import Dict
import Json.Decode as Decode exposing (Decoder)
import Netconf.Types exposing (..)
import EnTrance.Endpoint as Endpoint exposing (RpcData(..))
import EnTrance.Feature as Feature
import EnTrance.Persist as Persist
import Utils.Extra.Json.Encode as Encode


{-| The endpoint name
-}
endpoint : String
endpoint =
    "netconf"



{- The server feature name we want to start and monitor -}


feature : String
feature =
    "netconf"



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
            "netconf" ->
                rpcReply model.result
                    |> Decode.map NetconfNfn

            "persist_load" ->
                Persist.decode (Decode.dict Decode.string)
                    |> Decode.map PersistLoadNfn

            "connection_state" ->
                Feature.decodeConnectionState feature
                    |> Decode.map ConStateNfn

            unknown ->
                Decode.fail <| "Unknown netconf nfn_type: " ++ unknown



{-
   Send outgoing JSON requests
-}


sendReq : Request -> Model -> ( Model, Cmd Msg )
sendReq req model =
    let
        sendOpWithValue op value =
            Endpoint.request "netconf"
                |> Endpoint.addString "op" op
                |> Endpoint.addString "value" value

        sendOp op =
            Endpoint.request "netconf"
                |> Endpoint.addString "op" op
    in
        (case req of
            NetconfReq op ->
                case op of
                    Get value ->
                        sendOpWithValue "get" value

                    GetConfig value ->
                        sendOpWithValue "get_config" value

                    EditConfig value ->
                        sendOpWithValue "edit_config" value

                    Validate ->
                        sendOp "validate"

                    Commit ->
                        sendOp "commit"

            PersistSaveReq data ->
                Persist.save (Encode.dict data)

            PersistLoadReq ->
                -- Dict.empty is the default value to use if server has nothing stored
                Persist.load (Encode.dict Dict.empty)

            StartFeatureReq ->
                Feature.start feature Feature.SubscribeToConState
        )
            |> Endpoint.addDefaultTarget
            |> Endpoint.send model
