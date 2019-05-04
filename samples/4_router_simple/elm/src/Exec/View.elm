module Exec.View exposing (view)

{-| View for CLI Exec sub-app
-}

import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import EnTrance.Types exposing (RpcData)
import Exec.Types exposing (Model, Msg(..))
import Html exposing (Html, div, h4, pre, text)
import Html.Attributes exposing (autofocus, class, value)
import Html.Events exposing (onClick, onInput)
import RemoteData exposing (RemoteData(..))
import Utils.ViewHelper as ViewHelper



{-
   The view
-}


view : Model -> Html Msg
view model =
    div []
        [ h4 [] [ text "CLI Exec" ]
        , InputGroup.config
            (InputGroup.text
                [ Input.attrs
                    [ value model.cli
                    , autofocus True
                    , onInput UpdateCLI
                    ]
                ]
            )
            |> InputGroup.successors
                [ InputGroup.button
                    [ Button.outlinePrimary
                    , Button.attrs [ onClick Exec ]
                    , Button.disabled (not model.connectionIsUp)
                    ]
                    [ text "Go!" ]
                ]
            |> InputGroup.view
        , ViewHelper.maybeProgress model.result
        , renderResult model.result
        ]



{-
   How to render the actual result
-}


renderResult : RpcData String -> Html msg
renderResult rpcResult =
    case rpcResult of
        Failure reason ->
            div []
                [ Badge.badgeDanger [] [ text "Failure" ]
                , pre [ class "top-spacer" ] [ text reason ]
                ]

        Success result ->
            pre [ class "top-spacer" ] [ text result ]

        _ ->
            div [] []
