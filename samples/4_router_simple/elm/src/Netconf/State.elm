port module Netconf.State exposing
    ( clearAll
    , initialModel
    , subscriptions
    , update
    )

{-| Netconf state handling
-}

import EnTrance.Channel as Channel
import EnTrance.Feature.Persist as Persist
import EnTrance.Feature.Target.Netconf as Netconf exposing (Op(..))
import EnTrance.Types exposing (MaybeSubscribe(..))
import Json.Decode exposing (Decoder)
import Netconf.Types exposing (Model, Msg(..), NextOp(..))
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Utils.Inject as Inject
import Utils.Samples as Samples



-- Create channel ports


port netconfSend : Channel.SendPort msg


port netconfRecv : Channel.RecvPort msg


port netconfIsUp : Channel.IsUpPort msg


{-| Initial model
-}
initialModel : Model
initialModel =
    { xml = ""
    , -- dummy last netconf operation, doesn't matter
      lastOp = Commit
    , nextOp = NoneNext
    , samples = Samples.initialState "new-xml-sample"
    , result = NotAsked
    , connectionIsUp = False
    , sendPort = netconfSend
    }



{- The samples dropdown needs a subscription to close if you click away -}


{-| Subscriptions
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ netconfIsUp ChannelIsUp
        , Channel.sub netconfRecv Error decoders

        -- Samples dropdown needs a subscription to close if you click away
        , Samples.subscriptions
            model.samples
            |> Sub.map SamplesMsg
        ]


{-| Decoders for all the notifications we can receive
-}
decoders : List (Decoder Msg)
decoders =
    [ Netconf.decodeRequest DidNetconfOp
    , Netconf.decodeIsUp ConnectionIsUp
    , Persist.decodeLoad Samples.decoder PersistLoaded
    ]


{-| Update
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateXML xml ->
            pure { model | xml = xml }

        DoNetconfOp op ->
            let
                ( opToIssue, nextOp ) =
                    case op of
                        Validate ->
                            ( EditConfig model.xml, ValidateNext )

                        Commit ->
                            ( EditConfig model.xml, CommitNext )

                        _ ->
                            ( op, NoneNext )
            in
            Netconf.request opToIssue
                |> Channel.sendSimpleRpc
                    { model
                        | nextOp = nextOp
                        , lastOp = opToIssue
                    }

        Loaded name ->
            pure
                { model
                    | xml = Maybe.withDefault "" (Samples.get name model.samples)
                    , samples = Samples.setSaveName name model.samples
                }

        SamplesMsg sMsg ->
            Samples.update sMsg model model.xml Persist.saveAsync

        DidNetconfOp result ->
            case ( result, model.nextOp ) of
                -- If we just did a successful edit-config, then automatically
                -- kick off a validate or commit if that's what was teed up
                ( Success _, ValidateNext ) ->
                    Netconf.validate
                        |> Channel.sendSimpleRpc
                            { model
                                | lastOp = Validate
                                , nextOp = NoneNext
                            }

                ( Success _, CommitNext ) ->
                    Netconf.commit
                        |> Channel.sendSimpleRpc
                            { model
                                | lastOp = Commit
                                , nextOp = NoneNext
                            }

                _ ->
                    pure { model | result = result }

        PersistLoaded saves ->
            pure { model | samples = Samples.load saves model.samples }

        ConnectionIsUp isUp ->
            pure { model | connectionIsUp = isUp }

        ChannelIsUp True ->
            ( model
            , Channel.sendCmds netconfSend
                [ Persist.load Samples.empty
                , Netconf.start SubscribeToConState
                ]
            )

        ChannelIsUp False ->
            pure { model | connectionIsUp = False }

        Error error ->
            Inject.send (Inject.Error "netconf" error) model



{- User clicked the "Clear" button -}


clearAll : Model -> Model
clearAll model =
    { model | result = NotAsked }
