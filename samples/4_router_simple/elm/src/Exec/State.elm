port module Exec.State exposing
    ( clearAll
    , initialModel
    , subscriptions
    , update
    )

{-| State handling for CLI exec sub-app
-}

import EnTrance.Channel as Channel
import EnTrance.Feature.Target.CLI as CLI
import EnTrance.Types exposing (MaybeSubscribe(..))
import Exec.Types exposing (Model, Msg(..))
import Json.Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Utils.Inject as Inject



-- Create channel ports


port execSend : Channel.SendPort msg


port execRecv : Channel.RecvPort msg


port execIsUp : Channel.IsUpPort msg



{- Initial state -}


initialModel : Model
initialModel =
    { cli = ""
    , result = NotAsked
    , connectionIsUp = False
    , sendPort = execSend
    }


{-| Subscriptions
-}
subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ execIsUp ChannelIsUp
        , Channel.sub execRecv Error decoders
        ]


{-| Decoders for all the notifications we can receive
-}
decoders : List (Decoder Msg)
decoders =
    [ CLI.decodeExec ExecResult
    , CLI.decodeIsUp ConnectionIsUp
    ]



{- Updates -}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateCLI cli ->
            pure { model | cli = cli }

        Exec ->
            CLI.exec model.cli
                |> Channel.sendSimpleRpc model

        ExecResult result ->
            pure { model | result = result }

        ConnectionIsUp isUp ->
            pure { model | connectionIsUp = isUp }

        ChannelIsUp True ->
            CLI.start SubscribeToConState
                |> Channel.send model

        ChannelIsUp False ->
            pure { model | connectionIsUp = False }

        Error error ->
            Inject.send (Inject.Error "exec" error) model



{- User clicked the "Clear" button -}


clearAll : Model -> Model
clearAll model =
    { model | cli = "", result = NotAsked }
