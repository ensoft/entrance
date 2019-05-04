module View exposing (view)

{-| View
-}

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Progress as Progress
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import RemoteData exposing (RemoteData(..))
import Types exposing (..)


{-| Top-level view
-}
view : Model -> Html Msg
view model =
    Grid.container []
        [ Grid.row []
            [ Grid.col colSpec
                [ h4 [] [ text "EnTrance insecure shell example" ]
                , viewInput model.cmdText model.isUp
                , div [] (List.map (\x -> Alert.simpleDanger [] [ text x ]) model.errors)
                , div [ class "result" ]
                    [ case model.result of
                        NotAsked ->
                            div [ class "empty" ] [ text "No command issued" ]

                        Loading ->
                            Progress.progress [ Progress.value 100, Progress.animated ]

                        Success result ->
                            div []
                                [ maybeCode result.exitCode
                                , pre [ class "stdout" ] [ text result.stdout ]
                                , pre [ class "stderr" ] [ text result.stderr ]
                                ]

                        Failure error ->
                            div [ class "error" ] [ text ("Error: " ++ error) ]
                    ]
                ]
            ]
        ]


{-| Only display exit code if non-zero
-}
maybeCode : Int -> Html msg
maybeCode exitCode =
    if exitCode == 0 then
        text ""

    else
        div [ class "stderr" ] [ text ("Exit code " ++ String.fromInt exitCode) ]


{-| View the input area
-}
viewInput : String -> Bool -> Html Msg
viewInput dirText isUp =
    div []
        [ InputGroup.config
            (InputGroup.text
                [ Input.attrs
                    [ value dirText
                    , autofocus True
                    , onInput Input
                    , placeholder "Shell command to execute on the server"
                    ]
                ]
            )
            |> InputGroup.successors
                [ InputGroup.button
                    [ Button.outlineInfo
                    , Button.attrs [ onClick RunCmd ]
                    , Button.disabled (not isUp)
                    ]
                    [ text "Go!" ]
                ]
            |> InputGroup.view
        ]


{-| How the size should respond to the window size, expressed as units of a
grid 12 units across:

  - medium or bigger: 10 units wide (starting 1 from the left):
  - anything smaller: full width

You can see the effect by making your web browser window narrower and wider. A
more interesting example is in the `3_browser` view function, where there is
less need to support full-width content.

-}
colSpec : List (Col.Option msg)
colSpec =
    [ Col.md10
    , Col.offsetMd1
    ]
