module Utils.ViewHelper exposing (..)

{-|
   This module has a few helper functions that are handy when composing views
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Bootstrap.Progress as Progress
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Badge as Badge
import Bootstrap.Modal as Modal
import EnTrance.Endpoint as Endpoint exposing (RpcData)
import EnTrance.Ping as Ping


{-| An option progress bar for a RemoteData, that doesn't reflow the rest of the
layout when it is hiddenState
-}
maybeProgress : RpcData any -> Html msg
maybeProgress result =
    maybeColoredProgress (Endpoint.isLoading result) Blue


{-| An optional progress bar that can be either red or blue, and that doesn't
reflow the rest of the layout when hidden
-}
maybeColoredProgress : Bool -> ProgressCol -> Html msg
maybeColoredProgress show col =
    let
        progressBar options =
            div [ class "progress-spacer" ]
                [ Progress.progress <|
                    [ Progress.value 100
                    , Progress.height 5
                    , Progress.animated
                    ]
                        ++ options
                ]

        attrs =
            case col of
                Blue ->
                    []

                Red ->
                    [ Progress.danger ]

                Green ->
                    [ Progress.success ]
    in
        if show then
            progressBar attrs
        else
            div [ class "noprogress-spacer" ] []


type ProgressCol
    = Blue
    | Red
    | Green


{-| An optionally disabled ButtonGroup
-}
buttonGroup : Bool -> List ( String, msg ) -> Html msg
buttonGroup enabled buttonList =
    buttonList
        |> List.map
            (\( name, msg ) ->
                ButtonGroup.button
                    [ Button.outlinePrimary
                    , Button.small
                    , Button.attrs [ onClick msg ]
                    , Button.disabled (not enabled)
                    ]
                    [ text name ]
            )
        |> ButtonGroup.buttonGroup []


{-| A success/failure badge. (Which would you wear?)
-}
resultBadge : List (Attribute msg) -> RpcData r -> String -> Html msg
resultBadge attrs result name =
    case result of
        Endpoint.Success _ ->
            div attrs
                [ h5 []
                    [ Badge.badgeSuccess [] [ text <| name ++ " succeeded" ] ]
                ]

        Endpoint.Failure _ ->
            div attrs
                [ h5 []
                    [ Badge.badgeDanger [] [ text <| name ++ " failed" ] ]
                ]

        _ ->
            div attrs []


{-| A modal to confirm before doing something dangerous
-}
confirmModal : String -> String -> String -> String -> Modal.Visibility -> msg -> msg -> Html msg
confirmModal title warning confirmText cancelText state confirmMsg cancelMsg =
    Modal.config cancelMsg
        |> Modal.small
        |> Modal.h6 [] [ text title ]
        |> Modal.body []
            [ p [] [ text warning ] ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs [ onClick cancelMsg ]
                ]
                [ text cancelText ]
            , Button.button
                [ Button.danger
                , Button.attrs [ onClick confirmMsg ]
                ]
                [ text confirmText ]
            ]
        |> Modal.view state


{-| A model to use for ping timeout
-}
pingModal : Ping.State -> (Ping.Msg -> msg) -> Html msg
pingModal pingState pingMsg =
    let
        messages =
            [ "The server is unresponsive or network connectivity is lost."
            , "I'm afraid the app cannot function correctly until this is restored."
            , "This message will disappear automatically once the situation is rectified."
            ]

        visibility =
            if Ping.displayWarning pingState then
                Modal.shown
            else
                Modal.hidden

        abortMsg =
            pingMsg Ping.StopMonitoring
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
