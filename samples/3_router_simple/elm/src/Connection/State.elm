module Connection.State exposing (..)

{-|
   State handling for connections
-}

import Dict
import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import EnTrance.Endpoint as Endpoint
import Connection.Types exposing (..)
import Connection.Remote exposing (..)
import TopLevel.Types as TopLevel
import Response exposing (withCmd)
import Utils.Extra.Response exposing (pure, andThen)
import Utils.Inject as Inject
import Utils.Toast exposing (Toast(..))


{-
   Initial state
-}


initialModel : String -> Model
initialModel websocket =
    { connection = newConnection Endpoint.defaultTarget
    , newConnParams = defaultConnParams
    , modalVisibility = Modal.hidden
    , tabState = Tab.initialState
    , endpoint = Endpoint.named endpoint websocket
    }


newConnection : String -> Connection
newConnection name =
    { name = name
    , params = defaultConnParams
    , overallState = Disconnected
    , childStates = Dict.empty
    , stateHistory = []
    }


defaultConnParams : ConnParams
defaultConnParams =
    { host = ""
    , username = ""
    , secret = ""
    , authType = Password
    , sshPort = "22"
    , netconfPort = "830"
    , autoConnect = True
    }



{-
   When we are connected to the server, get any saved connection parameters, and
   also start listening for state change notifications for any individual
   connnections
-}


websocketUp : Model -> ( Model, Cmd Msg )
websocketUp model =
    sendReq (ParamsLoadReq defaultConnParams) model
        |> andThen (sendReq StartFeatureReq)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Modal.subscriptions model.modalVisibility AnimateModalMsg
        , Tab.subscriptions model.tabState TabMsg
        ]



{-
   Updates
-}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        connection =
            model.connection
    in
        case msg of
            ShowConnectionMsg ->
                pure { model | modalVisibility = Modal.shown }

            CancelMsg ->
                pure
                    { model
                        | newConnParams = model.connection.params
                        , modalVisibility = Modal.hidden
                    }

            SaveMsg ->
                sendReq (ParamsSaveReq model.newConnParams)
                    { model | connection = { connection | params = model.newConnParams } }

            ConnectAndSaveMsg ->
                sendReq (ConnectReq model.newConnParams)
                    { model | connection = { connection | params = model.newConnParams } }

            ConnectMsg ->
                sendReq (ConnectReq model.connection.params) model

            DisconnectMsg ->
                sendReq DisconnectReq model

            ConnParamsMsg msg_ ->
                pure { model | newConnParams = updateConnParams model.newConnParams msg_ }

            AnimateModalMsg visibility ->
                pure { model | modalVisibility = visibility }

            TabMsg state ->
                pure { model | tabState = state }



{- Update one field in the connection parameters form -}


updateConnParams : ConnParams -> ConnParamsMsg -> ConnParams
updateConnParams ncp msg =
    case msg of
        Host host ->
            { ncp | host = host }

        Username username ->
            { ncp | username = username }

        Secret secret ->
            { ncp | secret = secret }

        AuthType authType ->
            { ncp | authType = authType }

        SshPort sshPort ->
            { ncp | sshPort = sshPort }

        NetconfPort netconfPort ->
            { ncp | netconfPort = netconfPort }

        AutoConnect autoConnect ->
            { ncp | autoConnect = autoConnect }



{-
   Handle incoming notifications from the server.
   We return both a usual (Model, Cmd Msg) and also a Cmd TopLevel.Msg for
   injecting toasts back to the top level
-}


nfnUpdate : Notification -> Model -> ( ( Model, Cmd Msg ), Cmd TopLevel.Msg )
nfnUpdate nfn model =
    let
        connection =
            model.connection
    in
        case nfn of
            ParamsLoadNfn connParams ->
                let
                    paramsValid =
                        connParams.host /= "" && connParams.username /= ""

                    modalVisibility =
                        if paramsValid then
                            Modal.hidden
                        else
                            Modal.shown

                    newModel =
                        { model
                            | connection = { connection | params = connParams }
                            , newConnParams = connParams
                            , modalVisibility = modalVisibility
                        }
                in
                    if paramsValid && connParams.autoConnect then
                        sendReq (ConnectReq connParams) newModel
                            |> pure
                    else
                        pure newModel
                            |> pure

            ConnStateNfn childConnName childState overallState ts ->
                let
                    maybeToast =
                        if overallState /= model.connection.overallState then
                            withCmd (Inject.toast <| mapState overallState)
                        else
                            pure

                    newConnection =
                        { connection
                            | overallState = overallState
                            , childStates =
                                Dict.insert childConnName childState connection.childStates
                            , stateHistory =
                                ( ts, childConnName, childState, overallState )
                                    :: model.connection.stateHistory
                        }
                in
                    pure { model | connection = newConnection }
                        |> maybeToast



{- Map a connection state to a toast.
   @@@ This is really UI so should arguably move to the view
-}


mapState : ConnState -> Toast
mapState state =
    case state of
        Disconnected ->
            Success "Disconnected" ""

        Connected ->
            Success "Connected" ""

        FailureWhileDisconnecting why ->
            Danger "Failure while disconnecting" why

        Finalizing ->
            Info "Finalizing connection setup..." ""

        Connecting ->
            Info "Connecting..." ""

        Disconnecting ->
            Info "Disconnecting..." ""

        ReconnectingAfterFailure why ->
            Danger "Reconnecting after failure..." why

        FailedToConnect why ->
            Danger "Failed to connect" why
