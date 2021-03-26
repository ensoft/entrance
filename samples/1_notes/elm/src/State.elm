port module State exposing
    ( initialModel
    , subscriptions
    , update
    )

import EnTrance.Channel as Channel
import EnTrance.Feature.Persist as Persist
import Http exposing (expectJson)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..))
import Response exposing (pure, withCmd)
import Types exposing (Model, Msg(..))



{- PORTS

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


initialModel : Bool -> ( Model, Cmd Msg )
initialModel runningFromStatic =
    let
        cmd =
            if runningFromStatic then
                Http.get
                    { url = "/data.json"
                    , expect = expectJson (RemoteData.fromResult >> StaticData) decodeStaticData
                    }

            else
                Cmd.none

        decodeStaticData =
            Decode.list Decode.string
    in
    { runningFromStatic = runningFromStatic
    , editText = ""
    , notes = []
    , errors = []
    , result = NotAsked
    , staticData =
        if runningFromStatic then
            Loading

        else
            NotAsked
    , connected = False
    , sendPort = appSend
    }
        |> withCmd cmd


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.runningFromStatic then
        Sub.none

    else
        Sub.batch
            [ errorRecv Error
            , appIsUp ChannelIsUp
            , Channel.sub appRecv Error notifications
            ]


{-| The notifications we want to decode
-}
notifications : List (Decoder Msg)
notifications =
    [ Persist.decodeLoad decodeNotes Loaded
    , Persist.decodeSave Saved
    ]


decodeNotes : Decoder (List String)
decodeNotes =
    Decode.list Decode.string



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        updateNotes newNotes =
            -- Update the notes on both client and server with a new value
            Persist.save (Encode.list Encode.string newNotes)
                |> Channel.sendSimpleRpc
                    { model | notes = newNotes, editText = "" }
    in
    case msg of
        Input editText ->
            pure { model | editText = editText }

        Save ->
            updateNotes (model.editText :: model.notes)

        ClearAll ->
            updateNotes []

        Loaded notes ->
            -- Consider ourselves up at this point - websocket is up and we
            -- have the server's persisted state. It's ok to start sending
            -- edits from now on.
            pure { model | notes = notes, connected = True }

        Saved (Failure error) ->
            -- Save failures are uncommon, so just turn them into global errors
            -- rather than add UI just for this
            update (Error error) model

        Saved result ->
            pure { model | result = result }

        ChannelIsUp True ->
            -- Websocket up: load any previously saved notes. Empty list
            -- is the default value to use if nothing persisted.
            Persist.load (Encode.list Encode.string [])
                |> Channel.send model

        ChannelIsUp False ->
            pure { model | connected = False }

        Error error ->
            pure { model | errors = error :: model.errors }

        StaticData staticData ->
            pure { model | staticData = staticData }
