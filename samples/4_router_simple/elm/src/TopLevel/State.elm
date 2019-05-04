port module TopLevel.State exposing
    ( init
    , subscriptions
    , update
    )

{-| Top-level state management. This is mostly dispatching state to all the
sub-apps, with some top-level handling thrown in.
-}

import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Bootstrap.Tab as Tab
import Browser.Navigation as Navigation
import Config.State as Config
import Config.Types as Config
import Connection.State as Connection
import Connection.Types as Connection
import EnTrance.Channel as Channel
import EnTrance.Feature.Misc as Misc
import Exec.State as Exec
import Exec.Types as Exec
import Logs.State as Logs
import Logs.Types as Logs
import Netconf.State as Netconf
import Netconf.Types as Netconf
import Process
import Response exposing (andThen, mapBoth, pure, withCmd, withCmds)
import Task
import Toasty
import TopLevel.Types exposing (Model, Msg(..))
import Utils.Inject as Inject
import Utils.Toast as Toast


{-| PORTS : the global error reporting port, plus a SendPort just for
restarting the server (so no need for a RecvPort)
-}
port mainSend : Channel.SendPort msg


port errorRecv : Channel.ErrorRecvPort msg



-- INITIAL STATE


init : ( Model, Cmd Msg )
init =
    ( initialModel, initialCmds )


initialModel : Model
initialModel =
    let
        ( navbarState, _ ) =
            Navbar.initialState NavbarMsg
    in
    { -- Initial sub-models
      config = Config.initialModel
    , connection = Connection.initialModel
    , exec = Exec.initialModel
    , logs = Logs.initialModel
    , netconf = Netconf.initialModel
    , -- State for top-level UI elements
      navbarState = navbarState
    , toasties = Toasty.initialState
    , aboutModalVisibility = Modal.hidden
    , restartModalState = Modal.hidden
    , tabState = Tab.initialState
    , -- Global state
      errors = []
    }


{-| There aren't many initial commands, because we defer most initial
processing until we have established a connection with the server. The navbar
needs to query the window size straight away though.
-}
initialCmds : Cmd Msg
initialCmds =
    Tuple.second (Navbar.initialState NavbarMsg)


{-| Subscriptions
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ -- Sub-app subscriptions
          Config.subscriptions model.config
            |> Sub.map ConfigMsg
        , Connection.subscriptions model.connection
            |> Sub.map ConnectionMsg
        , Exec.subscriptions model.exec
            |> Sub.map ExecMsg
        , Logs.subscriptions model.logs
            |> Sub.map LogsMsg
        , Netconf.subscriptions model.netconf
            |> Sub.map NetconfMsg
        , -- Top-level UI subscriptions
          Modal.subscriptions model.aboutModalVisibility AnimateAboutModalMsg
        , Navbar.subscriptions model.navbarState NavbarMsg
        , Tab.subscriptions model.tabState TabMsg
        , -- The global subscriptions
          errorRecv Error
        , Inject.sub Injected
        ]



-- UPDATES


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        {-
           Sub-app delegation
        -}
        ConfigMsg msg_ ->
            Config.update msg_ model.config
                |> mapConfig model

        ConnectionMsg msg_ ->
            Connection.update msg_ model.connection
                |> mapConnection model

        ExecMsg msg_ ->
            Exec.update msg_ model.exec
                |> mapExec model

        LogsMsg msg_ ->
            Logs.update msg_ model.logs
                |> mapLogs model

        NetconfMsg msg_ ->
            Netconf.update msg_ model.netconf
                |> mapNetconf model

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

        ConfirmRestartMsg ->
            pure { model | restartModalState = Modal.shown }

        AbortRestartMsg ->
            pure { model | restartModalState = Modal.hidden }

        RestartServerMsg ->
            { model | restartModalState = Modal.hidden }
                |> withCmds
                    [ Misc.forceRestart
                        |> Channel.sendCmd mainSend
                    , injectMsgAfter 1000 RestartOurselvesMsg
                    ]

        RestartOurselvesMsg ->
            model
                |> withCmd Navigation.reload

        RestartModalMsg state ->
            pure { model | restartModalState = state }

        -- Global events
        Error error ->
            pure { model | errors = error :: model.errors }

        Injected (Inject.Error subsys error) ->
            let
                errMsg =
                    "[" ++ subsys ++ "] " ++ error
            in
            update (Error errMsg) model

        Injected (Inject.Toast toast) ->
            update (AddToast toast) model



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


mapNetconf : Model -> ( Netconf.Model, Cmd Netconf.Msg ) -> ( Model, Cmd Msg )
mapNetconf model =
    mapBoth (\x -> { model | netconf = x }) NetconfMsg


{-| Wait for a number of milliseconds before injecting a message as a command.
-}
injectMsgAfter : Float -> msg -> Cmd msg
injectMsgAfter time msg =
    Process.sleep time
        |> Task.andThen (always <| Task.succeed msg)
        |> Task.perform identity
