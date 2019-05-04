module TopLevel.Types exposing (Model, Msg(..))

{-| Top level types. This is a combination of aggregating the
Model/Msg/Notification types from sub-apps, and the remaining
Model/Msg/Notification elements for the top-level UI elements.
-}

import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Bootstrap.Tab as Tab
import Config.Types as Config
import Connection.Types as Connection
import Exec.Types as Exec
import Logs.Types as Logs
import Netconf.Types as Netconf
import Toasty
import Utils.Inject as Inject
import Utils.Toast exposing (Toast)


{-| Model
-}
type alias Model =
    -- Aggregate sub-models
    { config : Config.Model
    , connection : Connection.Model
    , exec : Exec.Model
    , logs : Logs.Model
    , netconf : Netconf.Model
    , -- Top-level UI element state
      navbarState : Navbar.State
    , toasties : Toasty.Stack Toast
    , aboutModalVisibility : Modal.Visibility
    , restartModalState : Modal.Visibility
    , tabState : Tab.State
    , -- Global state
      errors : List String
    }


{-| Messages
-}
type Msg
    = -- sub-app messages
      ConfigMsg Config.Msg
    | ConnectionMsg Connection.Msg
    | ExecMsg Exec.Msg
    | LogsMsg Logs.Msg
    | NetconfMsg Netconf.Msg
      -- top-level UI
    | TabMsg Tab.State
    | NavbarMsg Navbar.State
    | ToastyMsg (Toasty.Msg Toast)
    | AddToast Toast
    | AnimateAboutModalMsg Modal.Visibility
    | ClearAllMsg
    | ConfirmRestartMsg
    | AbortRestartMsg
    | RestartServerMsg
    | RestartOurselvesMsg
    | RestartModalMsg Modal.Visibility
      -- global errors and injected messages
    | Error String
    | Injected Inject.Msg
