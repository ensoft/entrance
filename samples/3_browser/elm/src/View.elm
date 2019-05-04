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
import Bootstrap.Table as Table
import EnTrance.Types exposing (RpcData)
import Html exposing (Html, div, h4, text)
import Html.Attributes exposing (autofocus, class, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Maybe.Extra exposing (isNothing)
import ReadDir exposing (Directory, EntryType(..))
import RemoteData exposing (RemoteData(..))
import State exposing (goBack)
import Types exposing (..)


{-| Top-level view
-}
view : Model -> Html Msg
view model =
    Grid.container []
        [ Grid.row []
            [ Grid.col colSpec
                [ h4 [] [ text "EnTrance directory browser example" ]
                , viewInput model.dirText model
                , div [] (List.map (\x -> Alert.simpleDanger [] [ text x ]) model.errors)
                , div [ class "result" ]
                    [ case model.result of
                        NotAsked ->
                            div [ class "empty" ] [ text "No directory specified" ]

                        Loading ->
                            Progress.progress [ Progress.value 100, Progress.animated ]

                        Success dir ->
                            viewDir dir

                        Failure error ->
                            div [ class "error" ] [ text ("Error: " ++ error) ]
                    ]
                ]
            ]
        ]


{-| View the input area
-}
viewInput : String -> Model -> Html Msg
viewInput dirText model =
    div []
        [ InputGroup.config
            (InputGroup.text
                [ Input.attrs
                    [ value dirText
                    , autofocus True
                    , onInput Input
                    , placeholder "Enter directory to browse here"
                    ]
                ]
            )
            |> InputGroup.successors
                [ InputGroup.button
                    [ Button.outlineInfo
                    , Button.attrs [ onClick (GotoDir dirText) ]
                    , Button.disabled (not model.connected)
                    ]
                    [ text "Go!" ]
                , InputGroup.button
                    [ Button.outlineInfo
                    , Button.attrs [ onClick GoBack ]
                    , Button.disabled
                        (isNothing (goBack model)
                            || not model.connected
                        )
                    ]
                    [ text "⇦ Back" ]
                , InputGroup.button
                    [ Button.outlineInfo
                    , Button.attrs [ onClick GoUp ]
                    , Button.disabled
                        (not (canGoUp model.result)
                            || not model.connected
                        )
                    ]
                    [ text "⇧ Up" ]
                ]
            |> InputGroup.view
        ]


{-| Can we go up a directory, from the current state?
-}
canGoUp : RpcData Directory -> Bool
canGoUp result =
    case result of
        Success dir ->
            if dir.fullPath == "/" then
                False

            else
                True

        _ ->
            False


{-| View the actual directory entries.
The text-\* classes are defined by bootstrap.
-}
viewDir : Directory -> Html Msg
viewDir dir =
    let
        format entry =
            case entry.entryType of
                File ->
                    Table.td [ Table.cellAttr <| class "text-secondary" ] [ text entry.name ]

                Dir ->
                    let
                        newDir =
                            dir.fullPath ++ "/" ++ entry.name
                    in
                    Table.td
                        [ Table.cellAttr <| class "text-info directory"
                        , Table.cellAttr <| onClick (GotoDir newDir)
                        ]
                        [ text <| entry.name ++ "/" ]

                Special ->
                    Table.td [ Table.cellAttr <| class "text-danger" ] [ text entry.name ]
    in
    Table.simpleTable
        ( Table.simpleThead [ Table.th [] [ text dir.fullPath ] ]
        , Table.tbody []
            (List.map (\x -> Table.tr [] [ format x ]) dir.entries)
        )


{-| How the size should respond to the window size, expressed as units of a
grid 12 units across:

  - extra-large: 6 units wide (starting 3 from the left)
  - large: 8 units wide (starting 2 from the left)
  - medium: 10 units wide (starting 1 from the left):
  - anything smaller: full width

You can see the effect by making your web browser window narrower and wider.

-}
colSpec : List (Col.Option msg)
colSpec =
    [ Col.xl6
    , Col.offsetXl3
    , Col.lg8
    , Col.offsetLg2
    , Col.md10
    , Col.offsetMd1
    ]
