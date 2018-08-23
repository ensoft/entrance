module Logs.View exposing (view)

{-|
   Logs view
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.ListGroup as ListGroup
import Utils.LoL as LoL exposing (..)
import Logs.Types exposing (..)


{-
   View
-}


view : Model -> Html Msg
view model =
    let
        renderOne i =
            ListGroup.li [] [ text i ]

        renderList l =
            ListGroup.ul (List.map renderOne l)
    in
        if LoL.isEmpty model.logs then
            div [ class "light" ] [ text "Logs will appear here when there are any" ]
        else
            div [] (LoL.map renderList model.logs)
