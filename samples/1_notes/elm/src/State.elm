module State exposing (initialModel, update, subscriptions)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Response exposing (Response, mapBoth, res)
import EnTrance.Endpoint as Endpoint exposing (Endpoint, defaultEndpoint)
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
        , endpoint = (Endpoint.default flags.websocket)
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        websocket =
            Endpoint.getWebSocket model.endpoint
    in
        Sub.batch
            [ Ping.subscriptions model.pingState |> Sub.map PingMsg
            , Notification.subscription ReceivedJSON websocket
            ]


websocketUp : Model -> ( Model, Cmd Msg )
websocketUp model =
    -- What to do when websocket connectivity is established
    let
        loadNotes m =
            -- Load any previously saved notes. The empty list is
            -- is the default value to use if nothing persisted.
            Encode.list []
                |> Persist.load
                |> Endpoint.send { m | connected = True }

        ping m =
            -- Start periodic pinging to verify server connectivity
            Ping.websocketUp model.pingState
                |> mapPing m
    in
        pure model
            |> andThen loadNotes
            |> andThen ping



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
            pure { model | notes = notes }

        GlobalNfn global ->
            let
                log msg =
                    let
                        _ =
                            Debug.log "Warning" msg
                    in
                        model
            in
                case global of
                    WebSocketUpNfn ->
                        websocketUp model

                    ErrorNfn error ->
                        pure { model | errors = error :: model.errors }

                    WarningNfn warning ->
                        pure <| log warning

                    PongNfn ->
                        pure { model | pingState = Ping.pongNotification model.pingState }



-- JSON DECODERS


nfnDecoder : String -> Model -> Decoder Notification
nfnDecoder nfnType model =
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
