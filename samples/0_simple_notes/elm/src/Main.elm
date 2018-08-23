module Main exposing (main)

{-| Single-module example EnTrance app - keep some notes
-}

import Html exposing (..)
import Html.Attributes exposing (class, placeholder, autofocus, value)
import Html.Events exposing (onInput, onClick)
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Grid as Grid
import EnTrance.Endpoint as Endpoint exposing (Endpoint, defaultEndpoint)
import EnTrance.Notification as Notification exposing (GlobalNfn(..))
import EnTrance.Persist as Persist


-- MODEL


type alias Model =
    { editText : String
    , notes : List String
    , errors : List String
    , connected : Bool
    , endpoint : Endpoint
    }


initialModel : String -> ( Model, Cmd Msg )
initialModel websocket =
    pure
        { editText = ""
        , notes = []
        , errors = []
        , connected = False
        , endpoint = (Endpoint.default websocket)
        }



-- MESSAGES AND NOTIFICATIONS


type Msg
    = Input String
    | Save
    | ClearAll
    | ReceivedJSON String


type Notification
    = Load (List String)
    | GlobalNfn GlobalNfn



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


nfnUpdate : Notification -> Model -> ( Model, Cmd Msg )
nfnUpdate notification model =
    case notification of
        Load notes ->
            -- Consider ourselves up at this point - websocket is up and we
            -- have the server's persisted state. It's ok to start sending
            -- edits from now on.
            pure { model | notes = notes, connected = True }

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
                        -- Websocket up: load any previously saved notes. Empty list
                        -- is the default value to use if nothing persisted.
                        Encode.list []
                            |> Persist.load
                            |> Endpoint.send model

                    ErrorNfn error ->
                        pure { model | errors = error :: model.errors }

                    WarningNfn warning ->
                        pure <| log warning

                    PongNfn ->
                        pure <| log "pong"



-- NOTIFICATION DECODING


nfnDecoder : String -> Model -> Decoder Notification
nfnDecoder nfnType model =
    case nfnType of
        "persist_load" ->
            Persist.decode (Decode.list Decode.string)
                |> Decode.map Load

        unknown_type ->
            Decode.fail <| "Unknown nfn_type: " ++ unknown_type



-- VIEW


{-| Top-level view
-}
view : Model -> Html Msg
view model =
    Grid.container []
        -- Even without explicit CSS, Bootstrap gives some handy
        -- classes for doing common things. Here 'my-3' means add
        -- 3 lots of margin to both top and bottom (both the 'y'
        -- directions) and 'mt-3' means add 3 lots of marging just
        -- to the top.
        [ h4 [ class "my-3" ] [ text "EnTrance demo notes app" ]
        , viewInput model.editText model.connected
        , div [] (listOf Alert.simpleDanger model.errors)
        , ul [ class "mt-3" ] (listOf li model.notes)
        ]


{-| View the input area
-}
viewInput : String -> Bool -> Html Msg
viewInput editText connected =
    div []
        [ InputGroup.config
            (InputGroup.text
                [ Input.attrs
                    [ value editText
                    , autofocus True
                    , onInput Input
                    , placeholder "Enter new note here"
                    ]
                ]
            )
            |> InputGroup.successors
                [ InputGroup.button
                    [ Button.outlinePrimary
                    , Button.attrs [ onClick Save ]
                    , Button.disabled (not connected)
                    ]
                    [ text "Save" ]
                , InputGroup.button
                    [ Button.outlinePrimary
                    , Button.attrs [ onClick ClearAll ]
                    , Button.disabled (not connected)
                    ]
                    [ text "Clear All" ]
                ]
            |> InputGroup.view
        ]


{-| Turn an html element constructor and a list of items into a list of elements
-}
listOf : (List attrs -> List (Html msg) -> elem) -> List String -> List elem
listOf elem items =
    List.map (\x -> elem [] [ text x ]) items



-- MAIN


main : Program { websocket : String } Model Msg
main =
    Html.programWithFlags
        { init = initialModel << .websocket
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Endpoint.subscription model.endpoint ReceivedJSON



-- helper (will be in elm-response soon)


pure : Model -> ( Model, Cmd msg )
pure model =
    ( model, Cmd.none )
