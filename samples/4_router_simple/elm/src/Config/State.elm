port module Config.State exposing
    ( clearAll
    , initialModel
    , subscriptions
    , update
    )

{-| State handling for the CLI config feature
-}

import Config.Types exposing (Model, Msg(..))
import EnTrance.Channel as Channel
import EnTrance.Feature.Persist as Persist
import EnTrance.Feature.Target.Config as Config exposing (CommitType(..))
import EnTrance.Request exposing (Request)
import EnTrance.Types exposing (MaybeSubscribe(..))
import Json.Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Utils.Inject as Inject
import Utils.Samples as Samples



-- Create channel ports


port configSend : Channel.SendPort msg


port configRecv : Channel.RecvPort msg


port configIsUp : Channel.IsUpPort msg


{-| Initial model
-}
initialModel : Model
initialModel =
    { config = ""
    , onlyCheck = False
    , rawView = False
    , commitResult = NotAsked
    , failuresResult = NotAsked
    , failures = []
    , samples = Samples.initialState "new-config-sample"
    , connectionIsUp = False
    , sendPort = configSend
    }


{-| Subscriptions
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ configIsUp ChannelIsUp
        , Channel.sub configRecv Error decoders

        -- Samples dropdown needs a subscription to close if you click away
        , Samples.subscriptions model.samples
            |> Sub.map SamplesMsg
        ]


{-| Decoders for all the notifications we can receive
-}
decoders : List (Decoder Msg)
decoders =
    [ Config.decodeLoad ConfigLoaded
    , Config.decodeCommit ConfigCommitted
    , Config.decodeGetFailures ConfigGotFailures
    , Config.decodeIsUp ConfigIsUp
    , Persist.decodeLoad Samples.decoder PersistLoaded
    ]


{-| Update
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CommitMsg onlyCheck ->
            Config.load model.config
                |> Channel.sendRpc
                    { model
                        | commitResult = Loading
                        , failuresResult = NotAsked
                        , failures = []
                        , onlyCheck = onlyCheck
                    }

        UpdateConfigMsg config ->
            pure { model | config = config }

        LoadMsg name ->
            pure
                { model
                    | config = Maybe.withDefault "" (Samples.get name model.samples)
                    , samples = Samples.setSaveName name model.samples
                }

        SamplesMsg sMsg ->
            Samples.update sMsg model model.config Persist.saveAsync

        RawViewMsg rawView ->
            pure { model | rawView = rawView }

        ChannelIsUp True ->
            ( model
            , Channel.sendCmds configSend
                [ Persist.load Samples.empty
                , Config.start SubscribeToConState
                ]
            )

        ChannelIsUp False ->
            pure { model | connectionIsUp = False }

        --
        -- Incoming notifications from server
        --
        ConfigLoaded (Success _) ->
            {- The config load operation worked, so go ahead and do
               the commit/validate operation the user actually wanted
            -}
            commitRequest model.onlyCheck
                |> Channel.sendRpc
                    { model | commitResult = Loading }

        ConfigLoaded result ->
            {- Config load didn't work - probably syntactic errors -}
            pure { model | commitResult = result }

        ConfigCommitted (Success result) ->
            -- Commit/validate worked
            pure { model | commitResult = Success result }

        ConfigCommitted _ ->
            -- Commit/validate failed - fetch the errors (slow)
            Config.getFailures
                |> Channel.sendRpc
                    { model
                        | commitResult = Failure "Rendering errors in CLI format..."
                        , failuresResult = Loading
                    }

        ConfigGotFailures result ->
            -- Retrieved the failures in CLI format
            pure
                { model
                    | failuresResult = result
                    , failures = Config.parseFailures result
                }

        ConfigIsUp isUp ->
            pure { model | connectionIsUp = isUp }

        PersistLoaded data ->
            pure { model | samples = Samples.load data model.samples }

        Error error ->
            Inject.send (Inject.Error "config" error) model


commitRequest : Bool -> Request
commitRequest onlyCheck =
    Config.commit
        (if onlyCheck then
            OnlyCheck

         else
            Commit
        )



{-
   "Clear" button clicked
-}


clearAll : Model -> Model
clearAll model =
    { model
        | commitResult = NotAsked
        , failuresResult = NotAsked
        , failures = []
    }
