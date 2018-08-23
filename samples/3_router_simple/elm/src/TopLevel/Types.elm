module TopLevel.Types exposing (..)

{-| Top level types. This is a combination of aggregating the
Model/Msg/Notification types from sub-apps, and the remaining
Model/Msg/Notification elements for the top-level UI elements.
-}

import Bootstrap.Tab as Tab
import Bootstrap.Navbar as Navbar
import Bootstrap.Modal as Modal
import Toasty
import EnTrance.Endpoint exposing (Endpoint)
import EnTrance.Notification exposing (GlobalNfn)
import EnTrance.Ping as Ping
import Config.Types as Config
import Connection.Types as Connection
import Exec.Types as Exec
import Logs.Types as Logs
import Netconf.Types as Netconf
import Utils.Toast exposing (Toast)


-- Model


type alias Model =
    -- Aggregate sub-models
    { config : Config.Model
    , connection : Connection.Model
    , exec : Exec.Model
    , logs : Logs.Model
    , netconf : Netconf.Model
    , -- Top-level UI element state
      pingState : Ping.State
    , navbarState : Navbar.State
    , toasties : Toasty.Stack Toast
    , aboutModalVisibility : Modal.Visibility
    , restartModalState : Modal.Visibility
    , debuggerPresent : Bool
    , debuggerVisible : Bool
    , errors : List String
    , tabState : Tab.State
    , endpoint : Endpoint
    }



-- Messages within the app


type Msg
    = -- sub-app messages
      ConfigMsg Config.Msg
    | ConnectionMsg Connection.Msg
    | ExecMsg Exec.Msg
    | LogsMsg Logs.Msg
    | NetconfMsg Netconf.Msg
    | PingMsg Ping.Msg
      -- top-level UI
    | TabMsg Tab.State
    | NavbarMsg Navbar.State
    | ToastyMsg (Toasty.Msg Toast)
    | AddToast Toast
    | AnimateAboutModalMsg Modal.Visibility
    | ToggleDebugMsg
    | ClearAllMsg
    | ConfirmRestartMsg
    | AbortRestartMsg
    | RestartServerMsg
    | RestartOurselvesMsg
    | RestartModalMsg Modal.Visibility
      -- incoming JSON
    | ReceivedJSON String



-- Notifications received from the server


type Notification
    = -- Sub-apps
      ConfigNfn Config.Notification
    | ConnectionNfn Connection.Notification
    | ExecNfn Exec.Notification
    | LogsNfn Logs.Notification
    | NetconfNfn Netconf.Notification
    | GlobalNfn GlobalNfn



-- Configuration provided by Javascript


type alias Flags =
    { websocket : String
    , debuggerPresent : Bool
    }
