module Utils.ViewHelper exposing
    ( ProgressCol(..)
    , buttonGroup
    , confirmModal
    , maybeColoredProgress
    , maybeProgress
    , resultBadge
    )

{-| This module has a few helper functions that are handy when composing views
-}

import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Modal as Modal
import Bootstrap.Progress as Progress
import EnTrance.Types exposing (RpcData)
import Html exposing (Attribute, Html, div, h5, p, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import RemoteData exposing (RemoteData(..), isLoading)


{-| An option progress bar for a RemoteData, that doesn't reflow the rest of the
layout when it is hiddenState
-}
maybeProgress : RpcData any -> Html msg
maybeProgress result =
    maybeColoredProgress (isLoading result) Blue


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


{-| What colour would you like your progress bar?
-}
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
        Success _ ->
            div attrs
                [ h5 []
                    [ Badge.badgeSuccess [] [ text <| name ++ " succeeded" ] ]
                ]

        Failure _ ->
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
