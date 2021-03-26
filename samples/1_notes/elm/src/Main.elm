module Main exposing (main)

{-| Single-module example EnTrance app - keep some notes
-}

import Browser
import State exposing (initialModel, subscriptions, update)
import Types exposing (Model, Msg)
import View exposing (view)



-- MAIN


main : Program Bool Model Msg
main =
    Browser.element
        { init = initialModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
