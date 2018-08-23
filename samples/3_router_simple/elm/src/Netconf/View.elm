module Netconf.View exposing (view)

{-|
   Netconf view
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Bootstrap.Form.Textarea as Textarea
import Markdown
import EnTrance.Endpoint exposing (RpcData(..))
import Netconf.Types exposing (..)
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
                , onInput UpdateXMLMsg
                ]
            ]
        , ViewHelper.maybeProgress model.result
        , ViewHelper.resultBadge [ class "float-right " ] model.result (opName model.lastOp)
        , ViewHelper.buttonGroup model.connectionUp
            [ ( "Get", NetconfOpMsg (Get model.xml) )
            , ( "Get Config", NetconfOpMsg (GetConfig model.xml) )
            , ( "Validate", NetconfOpMsg Validate )
            , ( "Commit", NetconfOpMsg Commit )
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
        LoadMsg



{-
   How to render a Netconf operation in the view
-}


opName : NetconfOp -> String
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
