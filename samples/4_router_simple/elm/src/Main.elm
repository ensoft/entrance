module Main exposing (main)

{-| Entrypoint for the app
-}

import Browser
import TopLevel.State exposing (init, subscriptions, update)
import TopLevel.Types exposing (Model, Msg)
import TopLevel.View exposing (view)


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
