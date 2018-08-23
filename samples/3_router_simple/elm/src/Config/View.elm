module Config.View exposing (..)

{-|
   View for CLI Config sub-app
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Form.Checkbox as Checkbox
import EnTrance.Endpoint exposing (RpcData(..), isLoading, isFailure)
import Utils.Samples as Samples
import Utils.ViewHelper as ViewHelper exposing (ProgressCol(..))
import Config.Types exposing (..)
import Config.Munge as Munge


{-
   The view
-}


view : Model -> Html Msg
view model =
    let
        showProgress =
            isLoading model.commitResult || isLoading model.failuresResult

        progressCol =
            if isLoading model.failuresResult then
                Red
            else
                Blue

        op =
            if model.checkOnly then
                "Validate"
            else
                "Commit"

        maybeCheckbox =
            if Munge.isEmpty model.mungedFailures then
                text ""
            else
                Checkbox.checkbox
                    [ Checkbox.checked model.rawView
                    , Checkbox.onCheck RawViewMsg
                    , Checkbox.inline
                    , Checkbox.attrs [ class "ml-1" ]
                    ]
                    "Raw"
    in
        div []
            [ Samples.view model.samples samplesConfig (String.isEmpty model.config)
            , h4 [] [ text "CLI Configuration" ]
            , Textarea.textarea
                [ Textarea.rows 7
                , Textarea.attrs
                    [ autofocus True
                    , value model.config
                    , onInput UpdateConfigMsg
                    ]
                ]
            , ViewHelper.maybeColoredProgress showProgress progressCol
            , ViewHelper.resultBadge [ class "float-right " ] model.commitResult op
            , ViewHelper.buttonGroup model.connectionUp
                [ ( "Validate", CommitMsg True )
                , ( "Commit", CommitMsg False )
                ]
            , maybeCheckbox
            , renderResult model
            ]



{-
   How to render the actual result
-}


renderResult : Model -> Html msg
renderResult model =
    let
        main =
            case ( model.commitResult, model.failuresResult ) of
                {- Successfully retrieved semantic errors -}
                ( _, Failure reason ) ->
                    reason

                {- No request to retrieve semantic errors, so just go on the
                   config load/commit state
                -}
                ( Failure reason, _ ) ->
                    reason

                _ ->
                    ""

        result =
            if not (isFailure model.failuresResult) || model.rawView then
                [ pre [ class "top-spacer errors" ] [ text main ] ]
            else
                [ viewMunged "Errors" model.mungedFailures model.failuresResult ]
    in
        div [] result


viewMunged : String -> Munge.Errors -> RpcData any -> Html mgs
viewMunged name munge result =
    if Munge.isEmpty munge then
        case result of
            Loading _ ->
                div [ class ("top-spacer " ++ String.toLower name) ]
                    [ text ("Rendering any " ++ String.toLower name ++ " as CLI...")
                    ]

            _ ->
                text ""
    else
        div [ class ("big-top-spacer " ++ String.toLower name) ] <|
            h5 [] [ text name ]
                :: List.map viewMungedError munge


viewMungedError : ( String, String ) -> Html msg
viewMungedError ( config, error ) =
    if String.isEmpty error then
        div [ class "config" ] [ text config ]
    else
        div []
            [ div [ class "config error" ] [ text config ]
            , div [ class "err-msg" ] [ text error ]
            ]



{-
   How we want the load/save samples reusable element to look here
-}


samplesConfig : Samples.Config Msg
samplesConfig =
    Samples.Config
        "Load"
        "Save"
        "Save Configuration"
        "Save configuration example with name:"
        [ class "float-right" ]
        SamplesMsg
        LoadMsg
