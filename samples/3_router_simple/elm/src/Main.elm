module Main exposing (main)

{-| Entrypoint for the app
-}

import Html
import TopLevel.Types exposing (..)
import TopLevel.State exposing (init, update, subscriptions)
import TopLevel.View exposing (view)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
