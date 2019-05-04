module Netconf.View exposing (view)

{-| Netconf view
-}

import Bootstrap.Form.Textarea as Textarea
import EnTrance.Feature.Target.Netconf exposing (Op(..))
import EnTrance.Types exposing (RpcData)
import Html exposing (Html, div, h4, text)
import Html.Attributes exposing (autofocus, class, value)
import Html.Events exposing (onInput)
import Markdown
import Netconf.Types exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Utils.Samples as Samples
import Utils.ViewHelper as ViewHelper



{-
   The view
-}


view : Model -> Html Msg
view model =
    div []
        [ Samples.view model.samples samplesConfig (String.isEmpty model.xml)
        , h4 [] [ text "Netconf" ]
        , Textarea.textarea
            [ Textarea.rows 7
            , Textarea.attrs
                [ autofocus True
                , value model.xml
                , onInput UpdateXML
                ]
            ]
        , ViewHelper.maybeProgress model.result
        , ViewHelper.resultBadge [ class "float-right " ] model.result (opName model.lastOp)
        , ViewHelper.buttonGroup model.connectionIsUp
            [ ( "Get", DoNetconfOp (Get model.xml) )
            , ( "Get Config", DoNetconfOp (GetConfig model.xml) )
            , ( "Validate", DoNetconfOp Validate )
            , ( "Commit", DoNetconfOp Commit )
            ]
        , "```xml\n"
            ++ renderResult model.result
            ++ "\n```"
            |> Markdown.toHtml [ class "top-spacer" ]
        ]



{-
   How to render the actual result
-}


renderResult : RpcData String -> String
renderResult rpcResult =
    case rpcResult of
        Success result2 ->
            result2

        Failure reason ->
            reason

        _ ->
            ""



{-
   Configuration for how we want the "load/save" samples to look
-}


samplesConfig : Samples.Config Msg
samplesConfig =
    Samples.Config
        "Load"
        "Save"
        "Save XML"
        "Save XML stanza with name:"
        [ class "float-right" ]
        SamplesMsg
        Loaded



{-
   How to render a Netconf operation in the view
-}


opName : Op -> String
opName op =
    case op of
        Get _ ->
            "Get"

        GetConfig _ ->
            "Get Config"

        EditConfig _ ->
            "Edit Config"

        Validate ->
            "Validate"

        Commit ->
            "Commit"
