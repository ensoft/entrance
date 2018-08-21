module View exposing (view)

{-| View
-}

import Html exposing (..)
import Html.Attributes exposing (class, placeholder, autofocus, value)
import Html.Events exposing (onInput, onClick)
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Grid as Grid
import Bootstrap.Modal as Modal
import EnTrance.Ping as Ping
import Types exposing (..)


{-| Top-level view
-}
view : Model -> Html Msg
view model =
    Grid.container []
        [ pingModal model.pingState
        , h4 [ class "my-3" ] [ text "EnTrance demo notes app" ]
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


pingModal : Ping.State -> Html Msg
pingModal pingState =
    let
        messages =
            [ "The server is unresponsive or network connectivity is lost."
            , "I'm afraid the app cannot function correctly until this is restored."
            , "This message will disappear automatically once the situation is rectified."
            ]

        visibility =
            case Ping.displayWarning pingState of
                True ->
                    Modal.shown

                False ->
                    Modal.hidden

        abortMsg =
            PingMsg Ping.StopMonitoring
    in
        Modal.config abortMsg
            |> Modal.large
            |> Modal.h3 [] [ text "Problem" ]
            |> Modal.body []
                (List.map (\x -> p [] [ text x ]) messages)
            |> Modal.footer []
                [ Button.button
                    [ Button.outlineDanger
                    , Button.attrs [ onClick abortMsg ]
                    ]
                    [ text "I don't care" ]
                ]
            |> Modal.view visibility
