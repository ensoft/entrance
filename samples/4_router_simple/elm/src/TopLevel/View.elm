module TopLevel.View exposing (view)

{-| Main view function - basically just piecing together all the sub-views. All
the top-level UI elements such as the "about" modal and debug are handled
by the Header module.
-}

import Bootstrap.Grid as Grid
import Bootstrap.Tab as Tab
import Config.View as Config
import Connection.View as Connection
import Exec.View as Exec
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Logs.View as Logs
import Netconf.View as Netconf
import Toasty
import Toasty.Defaults
import TopLevel.Header as Header
import TopLevel.Types exposing (Model, Msg(..))
import Utils.Toast as Toast


view : Model -> Html Msg
view model =
    Grid.container []
        [ Header.view model
        , Connection.view model.connection
            |> Html.map ConnectionMsg
        , div [ class "spacer" ] []
        , tabs model
        , Toasty.view Toasty.Defaults.config Toast.view ToastyMsg model.toasties
        ]


tabs : Model -> Html Msg
tabs model =
    Tab.config TabMsg
        |> Tab.withAnimation
        |> Tab.items
            [ tab "Exec" (Exec.view model.exec |> Html.map ExecMsg)
            , tab "Config" (Config.view model.config |> Html.map ConfigMsg)
            , tab "Netconf" (Netconf.view model.netconf |> Html.map NetconfMsg)
            , tab "Logs" (Logs.view model.logs |> Html.map LogsMsg)
            ]
        |> Tab.view model.tabState


tab : String -> Html Msg -> Tab.Item Msg
tab name subView =
    Tab.item
        { id = "Main" ++ name ++ "Tab"
        , link = Tab.link [] [ text name ]
        , pane =
            Tab.pane [ class "top-spacer" ] [ subView ]
        }
