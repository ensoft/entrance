port module TopLevel.State exposing (..)

{-|
   Top-level state management. This is mostly dispatching state to all the
   sub-apps, with some top-level handling thrown in.
-}

import Navigation
import Bootstrap.Tab as Tab
import Bootstrap.Navbar as Navbar
import Bootstrap.Modal as Modal
import Toasty
import Response exposing (mapBoth, withCmd)
import Utils.Extra.Response exposing (pure, withCmds, andThen)
import EnTrance.Endpoint as Endpoint
import EnTrance.Ping as Ping
import EnTrance.Notification as Notification exposing (GlobalNfn(..))
import TopLevel.Remote as Remote
import TopLevel.Types exposing (..)
import Config.State as Config
import Config.Types as Config
import Connection.State as Connection
import Connection.Types as Connection
import Exec.State as Exec
import Exec.Types as Exec
import Logs.State as Logs
import Logs.Types as Logs
import Netconf.State as Netconf
import Netconf.Types as Netconf
import Utils.Inject as Inject
import Utils.Toast as Toast


-- PORTS: toggle visibility of Elm debugger


port showDebugger : Bool -> Cmd msg



-- INITIAL STATE


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initialModel flags, initialCmds )


initialModel : Flags -> Model
initialModel flags =
    let
        ( navbarState, _ ) =
            Navbar.initialState NavbarMsg
    in
        { -- Initial sub-models
          config = Config.initialModel flags.websocket
        , connection = Connection.initialModel flags.websocket
        , exec = Exec.initialModel flags.websocket
        , logs = Logs.initialModel flags.websocket
        , netconf = Netconf.initialModel flags.websocket
        , -- State for top-level UI elements
          pingState = Ping.init flags.websocket
        , navbarState = navbarState
        , toasties = Toasty.initialState
        , aboutModalVisibility = Modal.hidden
        , restartModalState = Modal.hidden
        , debuggerPresent = flags.debuggerPresent
        , debuggerVisible = False
        , errors = []
        , tabState = Tab.initialState
        , endpoint = Endpoint.default flags.websocket
        }



{- There aren't many initial commands, because we defer most initial processing
   until we have established a connection with the server. The navbar needs to
   query the window size straight away though.
-}


initialCmds : Cmd Msg
initialCmds =
    Tuple.second (Navbar.initialState NavbarMsg)



{- Updates once our connection to the server is up -}


websocketUp : Model -> ( Model, Cmd Msg )
websocketUp model =
    {- Run all the websocketUp logic for the sub-apps and assemble the result. -}
    let
        update subUpdate mapper m =
            subUpdate m |> mapper m
    in
        ( model, Cmd.none )
            |> andThen (update (Exec.websocketUp << .exec) mapExec)
            |> andThen (update (Config.websocketUp << .config) mapConfig)
            |> andThen (update (Connection.websocketUp << .connection) mapConnection)
            |> andThen (update (Logs.websocketUp << .logs) mapLogs)
            |> andThen (update (Netconf.websocketUp << .netconf) mapNetconf)
            |> andThen (update (Ping.websocketUp << .pingState) mapPing)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ -- Sub-app subscriptions
          Config.subscriptions model.config |> Sub.map ConfigMsg
        , Connection.subscriptions model.connection |> Sub.map ConnectionMsg
        , Netconf.subscriptions model.netconf |> Sub.map NetconfMsg
        , -- Top-level UI subscriptions
          Ping.subscriptions model.pingState |> Sub.map PingMsg
        , Modal.subscriptions model.aboutModalVisibility AnimateAboutModalMsg
        , Navbar.subscriptions model.navbarState NavbarMsg
        , Tab.subscriptions model.tabState TabMsg
        , -- The incoming JSON request subscription
          Endpoint.subscription model.endpoint ReceivedJSON
        ]



-- UPDATES


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        {-
           Sub-app delegation
        -}
        ConfigMsg msg_ ->
            Config.update msg_ model.config |> mapConfig model

        ConnectionMsg msg_ ->
            Connection.update msg_ model.connection |> mapConnection model

        ExecMsg msg_ ->
            Exec.update msg_ model.exec |> mapExec model

        LogsMsg msg_ ->
            Logs.update msg_ model.logs |> mapLogs model

        NetconfMsg msg_ ->
            Netconf.update msg_ model.netconf |> mapNetconf model

        PingMsg msg_ ->
            Ping.update msg_ model.pingState |> mapPing model

        {-
           Incoming JSON notification from server
        -}
        ReceivedJSON notification ->
            nfnUpdate (Notification.decode Remote.cfg model notification) model

        {-
           Top level UI messages
        -}
        NavbarMsg state ->
            pure { model | navbarState = state }

        ToastyMsg msg_ ->
            Toasty.update Toast.config ToastyMsg msg_ model

        AddToast msg_ ->
            ( model, Cmd.none )
                |> Toasty.addToast Toast.config ToastyMsg msg_

        AnimateAboutModalMsg visibility ->
            pure { model | aboutModalVisibility = visibility }

        TabMsg state ->
            pure { model | tabState = state }

        ClearAllMsg ->
            pure
                { model
                    | config = Config.clearAll model.config
                    , exec = Exec.clearAll model.exec
                    , logs = Logs.clearAll model.logs
                    , netconf = Netconf.clearAll model.netconf
                    , errors = []
                }

        ToggleDebugMsg ->
            let
                visible =
                    not model.debuggerVisible
            in
                { model | debuggerVisible = visible }
                    |> withCmd (showDebugger visible)

        ConfirmRestartMsg ->
            pure { model | restartModalState = Modal.shown }

        AbortRestartMsg ->
            pure { model | restartModalState = Modal.hidden }

        RestartServerMsg ->
            { model | restartModalState = Modal.hidden }
                |> withCmds
                    [ Endpoint.forceRestart model.endpoint
                    , Inject.msgAfter 750 RestartOurselvesMsg
                    ]

        RestartOurselvesMsg ->
            model
                |> withCmd Navigation.reload

        RestartModalMsg state ->
            pure { model | restartModalState = state }



{-
   Notifications - received from the server and JSON-decoded by the Remote
   hierarchy, finally now dispatched down the nfnUpdate State hierarchy here.
-}


nfnUpdate : Notification -> Model -> ( Model, Cmd Msg )
nfnUpdate notification model =
    case notification of
        ConfigNfn nfn ->
            Config.nfnUpdate nfn model.config |> mapConfig model

        ConnectionNfn nfn ->
            -- Connection can inject top level messages (for toasts)
            Connection.nfnUpdate nfn model.connection
                |> mergeToplevelCmds mapConnection model

        ExecNfn nfn ->
            Exec.nfnUpdate nfn model.exec |> mapExec model

        LogsNfn nfn ->
            -- Logs can inject top level messages (for toasts)
            Logs.nfnUpdate nfn model.logs
                |> mergeToplevelCmds mapLogs model

        NetconfNfn nfn ->
            Netconf.nfnUpdate nfn model.netconf |> mapNetconf model

        GlobalNfn nfn ->
            case nfn of
                WebSocketUpNfn ->
                    websocketUp model

                PongNfn ->
                    { model | pingState = Ping.pongNotification model.pingState } ! []

                ErrorNfn error ->
                    { model | errors = error :: model.errors } ! []

                WarningNfn warning ->
                    let
                        _ =
                            Debug.log "Warning" warning
                    in
                        pure model



{-
   Merge in an optional third part of the result from an update-type function,
   which contains zero or more top-level commands to merge in
-}


mergeToplevelCmds :
    (Model -> ( model, Cmd msg ) -> ( Model, Cmd Msg ))
    -> Model
    -> ( ( model, Cmd msg ), Cmd Msg )
    -> ( Model, Cmd Msg )
mergeToplevelCmds mapper model ( response, toplevelCmds ) =
    let
        ( newModel, cmds ) =
            mapper model response
    in
        ( newModel, Cmd.batch [ cmds, toplevelCmds ] )



{- Mapping functions for all the sub-apps -}


mapConfig : Model -> ( Config.Model, Cmd Config.Msg ) -> ( Model, Cmd Msg )
mapConfig model =
    mapBoth (\x -> { model | config = x }) ConfigMsg


mapExec : Model -> ( Exec.Model, Cmd Exec.Msg ) -> ( Model, Cmd Msg )
mapExec model =
    mapBoth (\x -> { model | exec = x }) ExecMsg


mapConnection : Model -> ( Connection.Model, Cmd Connection.Msg ) -> ( Model, Cmd Msg )
mapConnection model =
    mapBoth (\x -> { model | connection = x }) ConnectionMsg


mapLogs : Model -> ( Logs.Model, Cmd Logs.Msg ) -> ( Model, Cmd Msg )
mapLogs model =
    mapBoth (\x -> { model | logs = x }) LogsMsg


mapPing : Model -> ( Ping.State, Cmd Ping.Msg ) -> ( Model, Cmd Msg )
mapPing model =
    mapBoth (\x -> { model | pingState = x }) PingMsg


mapNetconf : Model -> ( Netconf.Model, Cmd Netconf.Msg ) -> ( Model, Cmd Msg )
mapNetconf model =
    mapBoth (\x -> { model | netconf = x }) NetconfMsg
