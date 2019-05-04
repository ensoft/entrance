module Utils.Samples exposing
    ( Config
    , Data
    , Model
    , Msg(..)
    , State
    , decoder
    , empty
    , encode
    , get
    , initialState
    , load
    , setSaveName
    , subscriptions
    , update
    , view
    )

{-| This module implements a means to save and load "samples" (eg predefined
things to populate a textarea with). The load dropdown lets you choose from the
previously saved items (or delete them), and the save button lets you save the
current value as a new or existing item, at which point a modal dialog pops up
to confirm the save and the name for this sample.
-}

import Bootstrap.Button as Button
import Bootstrap.Dropdown as Dropdown
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Modal as Modal
import Dict exposing (Dict)
import EnTrance.Channel as Channel
import EnTrance.Request exposing (Request)
import Html exposing (Attribute, Html, div, p, text)
import Html.Attributes exposing (autofocus, class, value)
import Html.Events exposing (onClick, onInput, stopPropagationOn)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Response exposing (pure)
import Utils.ViewHelper as ViewHelper


type alias Data =
    Dict String String


empty : Value
empty =
    encode Dict.empty


encode : Data -> Value
encode =
    Encode.dict identity Encode.string


decoder : Decoder Data
decoder =
    Decode.dict Decode.string


{-| Internal state
-}
type alias State =
    { saves : Dict String String
    , loadDropdown : Dropdown.State
    , saveModal : Modal.Visibility
    , confirmDeleteModal : Modal.Visibility
    , deleteName : String
    , saveName : String
    }


initialState : String -> State
initialState saveName =
    { saves = Dict.empty
    , loadDropdown = Dropdown.initialState
    , saveModal = Modal.hidden
    , confirmDeleteModal = Modal.hidden
    , deleteName = ""
    , saveName = saveName
    }


{-| View Config - the using view function supplies ones of these, that tells
us how to render ourselves. THIS IS VIEW DATA, NOT MODEL DATA.
-}
type alias Config msg =
    { loadText : String
    , saveText : String
    , modalTitle : String
    , modalText : String
    , attrs : List (Attribute msg)
    , msgConstructor : Msg -> msg
    , loadMsg : String -> msg
    }


{-| Subscriptions
-}
subscriptions : State -> Sub Msg
subscriptions state =
    Dropdown.subscriptions state.loadDropdown LoadDropDown


{-| Messages we handle internally - this is basically everything other than
loading and saving from the persistence service
-}
type Msg
    = LoadDropDown Dropdown.State
    | SaveModal Modal.Visibility
    | AnimateModal Modal.Visibility
    | ConfirmDeleteModal String Modal.Visibility
    | Delete String
    | Save
    | UpdateSaveName String


{-| Accessor functions for the dict mapping names to samples - these just hide
the internal data structure choices
-}
get : String -> State -> Maybe String
get name state =
    Dict.get name state.saves


{-| setSaveName: set the default name that will appear in the "save" dialog box next
-}
setSaveName : String -> State -> State
setSaveName name state =
    { state | saveName = name }


load : Data -> State -> State
load saves state =
    { state | saves = saves }



{- Updates. For the sake of simplicity, assume that there is a single "samples"
   state entry in the parent model, called "samples". This assumption can be
   changed in future if necessary, but in the meantime, it meets the
   requirements and lets us remove boilerplate.
-}


type alias Model model msg =
    { model
        | samples : State
        , sendPort : Channel.SendPort msg
    }


update :
    Msg
    -> Model m msg
    -> String
    -> (Value -> Request)
    -> ( Model m msg, Cmd msg )
update msg oldModel value makeRequest =
    let
        state =
            oldModel.samples

        model newState =
            { oldModel | samples = newState }
    in
    case msg of
        LoadDropDown new ->
            pure <| model { state | loadDropdown = new }

        SaveModal new ->
            pure <| model { state | saveModal = new }

        AnimateModal visibility ->
            pure <| model { state | saveModal = visibility }

        UpdateSaveName new ->
            pure <| model { state | saveName = new }

        ConfirmDeleteModal name new ->
            pure <| model { state | confirmDeleteModal = new, deleteName = name }

        Delete name ->
            let
                saves =
                    Dict.remove name state.saves

                newModel =
                    model
                        { state
                            | saves = saves
                            , deleteName = ""
                            , confirmDeleteModal = Modal.hidden
                        }
            in
            makeRequest (encode saves)
                |> Channel.send newModel

        Save ->
            let
                saves =
                    Dict.insert state.saveName value state.saves

                newModel =
                    model
                        { state
                            | saves = saves
                            , saveModal = Modal.hidden
                        }
            in
            makeRequest (encode saves)
                |> Channel.send newModel


{-| Overall View: a load dropdown, a save button, a "save as" modal, and a
"confirm delete" modal
-}
view : State -> Config msg -> Bool -> Html msg
view state cfg isFieldEmpty =
    div cfg.attrs
        [ loadDropdownView state cfg
        , saveButtonView cfg isFieldEmpty
        , saveModalView state cfg
        , confirmDeleteModalView state cfg
        ]


{-| "Load" view
-}
loadDropdownView : State -> Config msg -> Html msg
loadDropdownView state cfg =
    Dropdown.dropdown
        state.loadDropdown
        { options = [ Dropdown.menuAttrs [ class "with-close" ] ]
        , toggleMsg = cfg.msgConstructor << LoadDropDown
        , toggleButton =
            Dropdown.toggle
                [ Button.outlineSecondary
                , Button.small
                , Button.disabled <| Dict.isEmpty state.saves
                ]
                [ text cfg.loadText ]
        , items =
            Dict.keys state.saves
                |> List.map
                    (\item ->
                        -- The actual item
                        Dropdown.anchorItem [ onClick <| cfg.loadMsg item ]
                            [ -- The "delete" cross to delete the item.
                              -- We have to work a bit harder than just
                              -- onClick here, to stop the event
                              -- propagating through to the enclosing anchor
                              Button.button
                                [ Button.attrs
                                    [ class "close"
                                    , ConfirmDeleteModal item Modal.shown
                                        |> cfg.msgConstructor
                                        |> onClickWithoutPropagating
                                    ]
                                ]
                                [ text "×" ]
                            , text item
                            ]
                    )
        }


onClickWithoutPropagating : msg -> Attribute msg
onClickWithoutPropagating msg =
    Decode.succeed ( msg, True )
        |> stopPropagationOn "click"


{-| "Save" button view
-}
saveButtonView : Config msg -> Bool -> Html msg
saveButtonView cfg isFieldEmpty =
    Button.button
        [ Button.outlineSecondary
        , Button.small
        , Button.disabled isFieldEmpty
        , Button.attrs
            [ SaveModal Modal.shown
                |> cfg.msgConstructor
                |> onClick
            ]
        ]
        [ text cfg.saveText ]


{-| "Save as" dialog view
-}
saveModalView : State -> Config msg -> Html msg
saveModalView state cfg =
    let
        cancelMsg =
            cfg.msgConstructor (SaveModal Modal.hidden)
    in
    Modal.config cancelMsg
        |> Modal.small
        |> Modal.withAnimation (cfg.msgConstructor << AnimateModal)
        |> Modal.h6 [] [ text cfg.modalTitle ]
        |> Modal.body []
            [ p [] [ text cfg.modalText ]
            , InputGroup.config
                (InputGroup.text
                    [ Input.attrs
                        [ value state.saveName
                        , autofocus True
                        , onInput (cfg.msgConstructor << UpdateSaveName)
                        ]
                    ]
                )
                |> InputGroup.view
            ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs [ onClick cancelMsg ]
                ]
                [ text "Cancel" ]
            , Button.button
                [ Button.primary
                , Button.attrs [ onClick <| cfg.msgConstructor Save ]
                ]
                [ text "Save" ]
            ]
        |> Modal.view state.saveModal


{-| "Confirm delete" modal
-}
confirmDeleteModalView : State -> Config msg -> Html msg
confirmDeleteModalView state cfg =
    ViewHelper.confirmModal
        "Confirm delete"
        ("Confirm deletion of '" ++ state.deleteName ++ "'? There is no undo.")
        "Delete"
        "Cancel"
        state.confirmDeleteModal
        (cfg.msgConstructor <| Delete state.deleteName)
        (cfg.msgConstructor <| ConfirmDeleteModal "" Modal.hidden)
