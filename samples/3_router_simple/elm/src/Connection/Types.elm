module Connection.Types exposing (..)

{-|
   Types for connection handling
-}

import Dict exposing (Dict)
import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import EnTrance.Endpoint exposing (Endpoint)


{-
   Model
-}


type alias Model =
    { connection : Connection
    , newConnParams : ConnParams
    , modalVisibility : Modal.Visibility
    , tabState : Tab.State
    , endpoint : Endpoint
    }


type alias Connection =
    { name : String
    , params : ConnParams
    , overallState : ConnState
    , childStates : Dict String ConnState
    , stateHistory : List ( String, String, ConnState, ConnState )
    }



{-
   Everything you need to connect to a router, plus whether or not to
   auto-connect when the app starts
-}


type alias ConnParams =
    { host : String
    , username : String
    , secret : String
    , authType : AuthType
    , sshPort : String
    , netconfPort : String
    , autoConnect : Bool
    }


type AuthType
    = Password
    | SshKey



{-
   Messages
-}


type Msg
    = -- invoked from top-level navbar
      ShowConnectionMsg
    | CancelMsg
    | SaveMsg
    | ConnectAndSaveMsg
    | ConnectMsg
    | DisconnectMsg
    | ConnParamsMsg ConnParamsMsg
    | AnimateModalMsg Modal.Visibility
    | TabMsg Tab.State


type ConnParamsMsg
    = Host String
    | Username String
    | Secret String
    | AuthType AuthType
    | SshPort String
    | NetconfPort String
    | AutoConnect Bool



{-
   Type describing the state of a connection. Only the failure states need a
   String to hold an error message
-}


type ConnState
    = Disconnected
    | Connected
    | FailureWhileDisconnecting String
    | Finalizing
    | Connecting
    | Disconnecting
    | ReconnectingAfterFailure String
    | FailedToConnect String



{-
   Requests outbound to the server
-}


type Request
    = ParamsLoadReq ConnParams
    | ParamsSaveReq ConnParams
    | ConnectReq ConnParams
    | DisconnectReq
    | StartFeatureReq



{-
   Notifications inbound from the server
-}


type Notification
    = ParamsLoadNfn ConnParams
    | ConnStateNfn String ConnState ConnState String
