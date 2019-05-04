module View exposing (view)

{-| View
-}

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Grid as Grid
import Bootstrap.Progress as Progress
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import RemoteData exposing (isLoading)
import Types exposing (Model, Msg(..))


{-| Top-level view
-}
view : Model -> Html Msg
view model =
    Grid.container []
        [ h4 [ class "my-3" ] [ text "EnTrance demo notes app" ]
        , viewInput model
        , maybeProgressBar (isLoading model.result)
        , div [] (listOf Alert.simpleDanger model.errors)
        , ul [ class "mt-3" ] (listOf li model.notes)
        ]


{-| View the input area
-}
viewInput : Model -> Html Msg
viewInput model =
    let
        disabled =
            not model.connected
                || isLoading model.result
    in
    div []
        [ InputGroup.config
            (InputGroup.text
                [ Input.attrs
                    [ value model.editText
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
                    , Button.disabled disabled
                    ]
                    [ text "Save" ]
                , InputGroup.button
                    [ Button.outlinePrimary
                    , Button.attrs [ onClick ClearAll ]
                    , Button.disabled disabled
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


{-| Render a progress bar if mid-save
-}
maybeProgressBar : Bool -> Html msg
maybeProgressBar inProgress =
    if inProgress then
        Progress.progress [ Progress.value 100, Progress.animated ]

    else
        text ""
