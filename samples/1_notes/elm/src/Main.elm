module Main exposing (main)

{-| Single-module example EnTrance app - keep some notes
-}

import Html
import Types exposing (..)
import State exposing (..)
import View exposing (view)


-- MAIN


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = initialModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
