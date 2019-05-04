port module State exposing
    ( goBack
    , initialModel
    , subscriptions
    , update
    )

import EnTrance.Channel as Channel
import Json.Decode exposing (Decoder)
import ReadDir exposing (decodeReadDir, readDir)
import RemoteData exposing (RemoteData(..), isFailure, isSuccess, unwrap)
import Response exposing (pure)
import Types exposing (..)


{-| PORTS

  - `appSend` - send message to the server
  - `appRecv` - receive a notification from the server
  - `appIsUp` - get notifications of up/down status
  - `errorRecv` - get any global errors

-}
port appSend : Channel.SendPort msg


port appRecv : Channel.RecvPort msg


port appIsUp : Channel.IsUpPort msg


port errorRecv : Channel.ErrorRecvPort msg



-- INITIAL STATE


initialModel : Model
initialModel =
    { dirText = ""
    , currentDir = "/"
    , result = NotAsked
    , history = []
    , connected = False
    , errors = []
    , sendPort = appSend
    }


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ errorRecv Error
        , appIsUp ChannelIsUp
        , Channel.sub appRecv Error notifications
        ]


notifications : List (Decoder Msg)
notifications =
    [ decodeReadDir ReceivedDir ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input dirText ->
            pure { model | dirText = dirText }

        GotoDir dir ->
            goToDir dir model

        GoUp ->
            case model.result of
                Success dir ->
                    -- The server normalises the path for us, so just go ahead with the simplest thing
                    goToDir (dir.fullPath ++ "/..") model

                _ ->
                    -- Should be some race condition, ignore
                    pure model

        GoBack ->
            case goBack model of
                Just ( path, history ) ->
                    goToDir path
                        { model | history = history }

                Nothing ->
                    pure model

        ReceivedDir result ->
            let
                history =
                    unwrap model.history (\x -> x.fullPath :: model.history) result

                dirText =
                    if isSuccess result then
                        ""

                    else
                        model.dirText
            in
            pure
                { model
                    | result = result
                    , history = history
                    , dirText = dirText
                }

        ChannelIsUp True ->
            goToDir model.currentDir
                { model | connected = True }

        ChannelIsUp False ->
            pure { model | connected = False }

        Error error ->
            pure { model | errors = error :: model.errors }


goToDir : String -> Model -> ( Model, Cmd Msg )
goToDir dir model =
    readDir dir
        |> Channel.sendSimpleRpc
            { model | currentDir = dir }


{-| If we can go back in history, return the path to fetch again, and the
new history from that point
-}
goBack : Model -> Maybe ( String, List String )
goBack model =
    if isFailure model.result then
        case model.history of
            lastSuccess :: history ->
                Just ( lastSuccess, history )

            _ ->
                Nothing

    else
        case model.history of
            _ :: prev :: history ->
                Just ( prev, history )

            _ ->
                Nothing
