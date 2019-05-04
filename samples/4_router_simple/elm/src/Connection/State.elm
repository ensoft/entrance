port module Connection.State exposing
    ( initialModel
    , subscriptions
    , update
    )

{-| State handling for connections
-}

import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import Connection.Misc exposing (..)
import Connection.Types exposing (..)
import Dict
import EnTrance.Channel as Channel
import EnTrance.Feature.Persist as Persist
import EnTrance.Feature.Target as Target
import EnTrance.Feature.Target.Connection as Con
import EnTrance.Feature.Target.Group as Group
import EnTrance.Types exposing (MaybeSubscribe(..))
import Json.Decode exposing (Decoder)
import Response exposing (andThen, pure)
import Utils.Inject as Inject
import Utils.Toast exposing (Toast(..))



-- Create channel ports


port connectionSend : Channel.SendPort msg


port connectionRecv : Channel.RecvPort msg


port connectionIsUp : Channel.IsUpPort msg


{-| Initial state
-}
initialModel : Model
initialModel =
    { connection = newConnection
    , newConnPrefs = defaultConnPrefs
    , modalVisibility = Modal.hidden
    , tabState = Tab.initialState
    , sendPort = connectionSend
    }


newConnection : Connection
newConnection =
    { prefs = defaultConnPrefs
    , groupState = Con.Disconnected
    , childStates = Dict.empty
    , stateHistory = []
    }


defaultConnPrefs : ConnPrefs
defaultConnPrefs =
    { params =
        { host = ""
        , username = ""
        , secret = ""
        , authType = Con.Password
        , sshPort = "22"
        , netconfPort = "830"
        }
    , autoConnect = True
    }


{-| Subscriptions
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ connectionIsUp ChannelIsUp
        , Channel.sub connectionRecv Error decoders
        , Modal.subscriptions model.modalVisibility AnimateModal
        , Tab.subscriptions model.tabState TabMsg
        ]


{-| Decoders for all the notifications we can receive
-}
decoders : List (Decoder Msg)
decoders =
    [ Con.decodeGroupState ConnectionState
    , Persist.decodeLoad decodeConnPrefs ConnPrefsLoaded
    ]


{-| Updates
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        connection =
            model.connection
    in
    case msg of
        ShowConnection ->
            pure { model | modalVisibility = Modal.shown }

        Cancel ->
            pure
                { model
                    | newConnPrefs = model.connection.prefs
                    , modalVisibility = Modal.hidden
                }

        Save ->
            Persist.saveAsync (encodeConnPrefs model.newConnPrefs)
                |> Channel.send
                    (setConnPrefs model model.newConnPrefs)

        ConnectAndSave ->
            update Save model
                |> andThen (update Connect)

        Connect ->
            Target.connect model.connection.prefs.params
                |> Channel.send model

        Disconnect ->
            Target.disconnect
                |> Channel.send model

        ConnPrefsEdit edit ->
            pure { model | newConnPrefs = updateConnPrefs model.newConnPrefs edit }

        AutoConnectEdit autoConnect ->
            let
                ncp =
                    model.newConnPrefs
            in
            pure { model | newConnPrefs = { ncp | autoConnect = autoConnect } }

        AnimateModal visibility ->
            pure { model | modalVisibility = visibility }

        TabMsg state ->
            pure { model | tabState = state }

        ConnPrefsLoaded connPrefs ->
            let
                paramsValid =
                    connPrefs.params.host /= "" && connPrefs.params.username /= ""

                modalVisibility =
                    if paramsValid then
                        Modal.hidden

                    else
                        Modal.shown

                newModel =
                    { model
                        | connection = { connection | prefs = connPrefs }
                        , newConnPrefs = connPrefs
                        , modalVisibility = modalVisibility
                    }
            in
            if paramsValid && connPrefs.autoConnect then
                Target.connect connPrefs.params
                    |> Channel.send newModel

            else
                pure newModel

        ConnectionState { groupState, childName, childState, timestamp } ->
            let
                maybeToast =
                    if groupState /= model.connection.groupState then
                        Inject.send (Inject.Toast <| toToast groupState)

                    else
                        pure

                newCon =
                    { connection
                        | groupState = groupState
                        , childStates =
                            Dict.insert childName childState connection.childStates
                        , stateHistory =
                            Entry timestamp childName childState groupState
                                :: model.connection.stateHistory
                    }
            in
            { model | connection = newCon }
                |> maybeToast

        ChannelIsUp True ->
            ( model
            , Channel.sendCmds connectionSend
                [ Persist.load (encodeConnPrefs defaultConnPrefs)
                , Group.start SubscribeToConState
                ]
            )

        ChannelIsUp False ->
            pure { model | connection = { connection | groupState = Con.Disconnected } }

        Error error ->
            Inject.send (Inject.Error "connection" error) model



{- Update one field in the connection parameters form -}


updateConnPrefs : ConnPrefs -> ConnPrefsField -> ConnPrefs
updateConnPrefs ncp edit =
    let
        params =
            ncp.params
    in
    case edit of
        Host host ->
            { ncp | params = { params | host = host } }

        Username username ->
            { ncp | params = { params | username = username } }

        Secret secret ->
            { ncp | params = { params | secret = secret } }

        AuthType authType ->
            { ncp | params = { params | authType = authType } }

        SshPort sshPort ->
            { ncp | params = { params | sshPort = sshPort } }

        NetconfPort netconfPort ->
            { ncp | params = { params | netconfPort = netconfPort } }

        AutoConnect autoConnect ->
            { ncp | autoConnect = autoConnect }
