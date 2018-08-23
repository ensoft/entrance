module State exposing (initialModel, update, subscriptions)

import Dict
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Response exposing (Response, mapBoth, res)
import EnTrance.Endpoint as Endpoint exposing (defaultEndpoint)
import EnTrance.Notification as Notification exposing (GlobalNfn(..))
import EnTrance.Persist as Persist
import EnTrance.Ping as Ping
import Types exposing (..)


-- INITIAL STATE


initialModel : Flags -> ( Model, Cmd Msg )
initialModel flags =
    pure
        { editText = ""
        , notes = []
        , errors = []
        , connected = False
        , pingState = Ping.init flags.websocket
        , endpoint = Endpoint.default flags.websocket
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Endpoint.subscription model.endpoint ReceivedJSON
        , Ping.subscriptions model.pingState |> Sub.map PingMsg
        ]


websocketUp : Model -> ( Model, Cmd Msg )
websocketUp model =
    let
        loadNotes m defaultValue =
            Encode.list defaultValue
                |> Persist.load
                |> Endpoint.send m

        startPinging m =
            Ping.websocketUp model.pingState
                |> mapPing m
    in
        loadNotes model []
            |> andThen startPinging



-- ENDPOINT CONFIG


{-| Just two endpoints: the Global one for things like top-level errors, and
one other default endpoint for our actual app logic.
-}
cfg : Notification.Config Model Notification
cfg =
    Notification.Config
        GlobalNfn
        (Dict.fromList [ ( defaultEndpoint, nfnDecoder ) ])



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        updateNotes newNotes =
            -- Update the notes on both client and server with a new value
            Encode.list (List.map Encode.string newNotes)
                |> Persist.save
                |> Endpoint.send { model | notes = newNotes, editText = "" }
    in
        case msg of
            Input editText ->
                pure { model | editText = editText }

            Save ->
                updateNotes (model.editText :: model.notes)

            ClearAll ->
                updateNotes []

            ReceivedJSON json ->
                nfnUpdate (Notification.decode cfg model json) model

            PingMsg subMsg ->
                Ping.update subMsg model.pingState |> mapPing model



-- UPDATE FROM A NOTIIFCATION


nfnUpdate : Notification -> Model -> ( Model, Cmd Msg )
nfnUpdate notification model =
    case notification of
        Load notes ->
            -- Consider ourselves up at this point - websocket is up and we
            -- have the server's persisted state. It's ok to start sending
            -- edits from now on.
            pure { model | notes = notes, connected = True }

        GlobalNfn global ->
            case global of
                WebSocketUpNfn ->
                    websocketUp model

                ErrorNfn error ->
                    pure { model | errors = error :: model.errors }

                WarningNfn warning ->
                    pure { model | errors = warning :: model.errors }

                PongNfn ->
                    pure { model | pingState = Ping.pongNotification model.pingState }



-- JSON DECODERS


nfnDecoder : String -> Model -> Decoder Notification
nfnDecoder nfnType _ =
    case nfnType of
        "persist_load" ->
            Persist.decode (Decode.list Decode.string)
                |> Decode.map Load

        unknown_type ->
            Decode.fail <| "Unknown nfn_type: " ++ unknown_type



-- Helpers (pure and andThen will be in elm-response soon)


pure : Model -> ( Model, Cmd msg )
pure model =
    ( model, Cmd.none )


andThen : (model -> Response model a) -> Response model a -> Response model a
andThen update ( model1, cmd1 ) =
    let
        ( model2, cmd2 ) =
            update model1
    in
        res model2 (Cmd.batch [ cmd1, cmd2 ])


mapPing : Model -> ( Ping.State, Cmd Ping.Msg ) -> ( Model, Cmd Msg )
mapPing model =
    mapBoth (\x -> { model | pingState = x }) PingMsg
