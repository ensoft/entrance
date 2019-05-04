module Logs.View exposing (view)

{-| Logs view
-}

import Bootstrap.ListGroup as ListGroup
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Logs.Types exposing (Model, Msg(..))
import Utils.LoL as LoL


{-| View
-}
view : Model -> Html msg
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
