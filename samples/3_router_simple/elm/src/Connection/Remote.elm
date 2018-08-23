module Connection.Remote exposing (endpoint, nfnDecoder, sendReq)

{-|
   Remote handling of the connections established by the server to the router
-}

import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import EnTrance.Endpoint as Endpoint
import EnTrance.Feature as Feature
import EnTrance.Persist as Persist
import Connection.Types exposing (..)


{-| The endpoint name
-}
endpoint : String
endpoint =
    "connection"



{- The feature name we need to start -}


feature : String
feature =
    "target_group"



{-
   Decode incoming JSON notifications
-}


nfnDecoder : Model -> String -> Decoder Notification
nfnDecoder _ nfnType =
    case nfnType of
        "persist_load" ->
            Persist.decode decodeParams
                |> Decode.map ParamsLoadNfn

        "connection_state" ->
            Decode.map4 ConnStateNfn
                (Decode.field "child" Decode.string)
                (Decode.field "child_state" decodeConnState)
                (Decode.field "state" decodeConnState)
                (Decode.field "timestamp" Decode.string)

        unknown_type ->
            Decode.fail <| "Unknown connection nfn_type: " ++ unknown_type


decodeConnState : Decoder ConnState
decodeConnState =
    let
        connState str err =
            case str of
                "DISCONNECTED" ->
                    Decode.succeed Disconnected

                "CONNECTED" ->
                    Decode.succeed Connected

                "FAILURE_WHILE_DISCONNECTING" ->
                    Decode.succeed <| FailureWhileDisconnecting err

                "FINALIZING" ->
                    Decode.succeed Finalizing

                "CONNECTING" ->
                    Decode.succeed Connecting

                "DISCONNECTING" ->
                    Decode.succeed Disconnecting

                "RECONNECTING_AFTER_FAILURE" ->
                    Decode.succeed <| ReconnectingAfterFailure err

                "FAILED_TO_CONNECT" ->
                    Decode.succeed <| FailedToConnect err

                unknown ->
                    Decode.fail <| "Unknown connection state: " ++ unknown
    in
        Decode.map2 connState
            (Decode.field "state" Decode.string)
            (Decode.field "error" Decode.string)
            |> Decode.andThen identity


decodeParams : Decoder ConnParams
decodeParams =
    let
        authType authIsPassword =
            if authIsPassword then
                Password
            else
                SshKey
    in
        Decode.map7 ConnParams
            (Decode.field "host" Decode.string)
            (Decode.field "username" Decode.string)
            (Decode.field "secret" Decode.string)
            (Decode.field "auth_is_password" (Decode.bool |> Decode.map authType))
            (Decode.field "ssh_port" Decode.string)
            (Decode.field "netconf_port" Decode.string)
            (Decode.field "auto_connect" Decode.bool)



{-
   Send outgoing JSON requests
-}


sendReq : Request -> Model -> ( Model, Cmd Msg )
sendReq req model =
    (case req of
        ParamsLoadReq default ->
            Persist.load (encodeParams default)

        ParamsSaveReq params ->
            Persist.save (encodeParams params)

        ConnectReq params ->
            Endpoint.request "connect"
                |> Endpoint.addValue "params" (encodeParams params)
                |> Endpoint.addString "connection_type" "ssh"

        DisconnectReq ->
            Endpoint.request "disconnect"

        StartFeatureReq ->
            Feature.start feature Feature.SubscribeToConState
    )
        |> Endpoint.addDefaultTarget
        |> Endpoint.send model


encodeParams : ConnParams -> Encode.Value
encodeParams params =
    [ ( "host", Encode.string params.host )
    , ( "username", Encode.string params.username )
    , ( "secret", Encode.string params.secret )
    , ( "auth_is_password", Encode.bool (params.authType == Password) )
    , ( "ssh_port", Encode.string params.sshPort )
    , ( "netconf_port", Encode.string params.netconfPort )
    , ( "auto_connect", Encode.bool params.autoConnect )
    ]
        |> Encode.object
