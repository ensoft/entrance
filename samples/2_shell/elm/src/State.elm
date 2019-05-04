port module State exposing (initialModel, subscriptions, update)

import EnTrance.Channel as Channel
import InsecureShell
import Json.Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..))
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
    { cmdText = ""
    , result = NotAsked
    , isUp = False
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
    [ InsecureShell.decodeCmd GotResult ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input cmdText ->
            pure { model | cmdText = cmdText }

        RunCmd ->
            InsecureShell.cmd model.cmdText
                |> Channel.sendSimpleRpc model

        GotResult result ->
            pure { model | result = result }

        ChannelIsUp isUp ->
            pure { model | isUp = isUp }

        Error error ->
            pure { model | errors = error :: model.errors }
