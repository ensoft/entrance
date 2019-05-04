module Main exposing (main)

{-| Single-module example EnTrance app to browse files
-}

import Browser
import Response exposing (pure)
import State exposing (initialModel, subscriptions, update)
import Types exposing (Model, Msg)
import View exposing (view)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> pure initialModel
        , view = view
        , update = update
        , subscriptions = \_ -> subscriptions
        }
