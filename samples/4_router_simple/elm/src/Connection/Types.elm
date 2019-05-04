module Connection.Types exposing
    ( ConnPrefs
    , ConnPrefsField(..)
    , Connection
    , Entry
    , Model
    , Msg(..)
    )

{-| Types for connection handling
-}

import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import Dict exposing (Dict)
import EnTrance.Channel as Channel
import EnTrance.Feature.Target.Connection as Connection


{-| Model
-}
type alias Model =
    { connection : Connection
    , newConnPrefs : ConnPrefs
    , modalVisibility : Modal.Visibility
    , tabState : Tab.State
    , sendPort : Channel.SendPort Msg
    }


type alias Connection =
    { prefs : ConnPrefs
    , groupState : Connection.State
    , childStates : Dict String Connection.State
    , stateHistory : List Entry
    }


type alias Entry =
    { time : String
    , connection : String
    , state : Connection.State
    , globalState : Connection.State
    }


{-| Everything you need to connect to a router, plus whether or not to
auto-connect when the app starts
-}
type alias ConnPrefs =
    { params : Connection.Params
    , autoConnect : Bool
    }


{-| Messages
-}
type Msg
    = -- invoked from top-level navbar
      ShowConnection
    | Cancel
    | Save
    | ConnectAndSave
    | Connect
    | Disconnect
    | ConnPrefsEdit ConnPrefsField
    | AutoConnectEdit Bool
    | AnimateModal Modal.Visibility
    | TabMsg Tab.State
    | ConnPrefsLoaded ConnPrefs
    | ConnectionState Connection.GroupState
    | ChannelIsUp Bool
    | Error String


type ConnPrefsField
    = Host String
    | Username String
    | Secret String
    | AuthType Connection.AuthType
    | SshPort String
    | NetconfPort String
    | AutoConnect Bool
