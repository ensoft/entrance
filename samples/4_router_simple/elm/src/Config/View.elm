module Config.View exposing (view)

{-| View for CLI Config sub-app
-}

import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Textarea as Textarea
import Config.Types exposing (Model, Msg(..))
import EnTrance.Feature.Target.Config as Config
import EnTrance.Types exposing (RpcData)
import Html exposing (Html, div, h4, h5, pre, text)
import Html.Attributes exposing (autofocus, class, value)
import Html.Events exposing (onInput)
import RemoteData exposing (RemoteData(..), isFailure, isLoading)
import Utils.Samples as Samples
import Utils.ViewHelper as ViewHelper exposing (ProgressCol(..))


{-| The view
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
            if model.onlyCheck then
                "Validate"

            else
                "Commit"

        maybeCheckbox =
            if List.isEmpty model.failures then
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
        , ViewHelper.buttonGroup model.connectionIsUp
            [ ( "Validate", CommitMsg True )
            , ( "Commit", CommitMsg False )
            ]
        , maybeCheckbox
        , renderResult model
        ]


{-| How to render the actual result
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
                [ viewFailures "Errors" model.failures model.failuresResult ]
    in
    div [] result


viewFailures : String -> List Config.Failed -> RpcData any -> Html mgs
viewFailures name failures result =
    if List.isEmpty failures then
        if isLoading result then
            div [ class ("top-spacer " ++ String.toLower name) ]
                [ text ("Rendering any " ++ String.toLower name ++ " as CLI...")
                ]

        else
            text ""

    else
        div [ class ("big-top-spacer " ++ String.toLower name) ] <|
            h5 [] [ text name ]
                :: List.map viewFailure failures


viewFailure : Config.Failed -> Html msg
viewFailure { config, error } =
    if String.isEmpty error then
        div [ class "config" ] [ text config ]

    else
        div []
            [ div [ class "config error" ] [ text config ]
            , div [ class "err-msg" ] [ text error ]
            ]


{-| How we want the load/save samples reusable element to look here
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
