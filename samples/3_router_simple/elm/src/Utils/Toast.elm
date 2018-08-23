module Utils.Toast exposing (..)

{-| Adapts the generic Toasty package for our specific use with Bootstrap
-}

import Html exposing (..)
import Html.Attributes exposing (class)
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Toasty


{- Type for toasts -}


type Toast
    = Info String String
    | Success String String
    | Warning String String
    | Danger String String



{- Configuraton options -}


config : Toasty.Config msg
config =
    Toasty.config
        |> Toasty.transitionOutDuration 500
        |> Toasty.delay 5000



{- View -}


view : Toast -> Html msg
view toast =
    let
        ( severity, title, message ) =
            case toast of
                Info t m ->
                    ( Card.info, t, m )

                Success t m ->
                    ( Card.success, t, m )

                Warning t m ->
                    ( Card.warning, t, m )

                Danger t m ->
                    ( Card.danger, t, m )

        maybeMessage =
            if message /= "" then
                [ Block.text [] [ text message ] ]
            else
                []
    in
        div [ class "toasts" ]
            [ Card.config [ severity ]
                |> Card.block []
                    (Block.titleH6 [] [ text title ] :: maybeMessage)
                |> Card.view
            ]
