module Exec.View exposing (view)

{-|
   View for CLI Exec sub-app
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import EnTrance.Endpoint exposing (RpcData(..))
import Utils.ViewHelper as ViewHelper
import Exec.Types exposing (..)


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
                    , onInput UpdateCLIMsg
                    ]
                ]
            )
            |> InputGroup.successors
                [ InputGroup.button
                    [ Button.outlinePrimary
                    , Button.attrs [ onClick ExecMsg ]
                    , Button.disabled (not model.connectionUp)
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
