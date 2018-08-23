module Netconf.Types exposing (..)

{-|
   Netconf types
-}

import Dict exposing (Dict)
import EnTrance.Endpoint exposing (Endpoint, RpcData)
import Utils.Samples as Samples


{-
   Model. We keep track of the last Netconf operation to be initiated, so
   we can report the success/failure state meaningfully. We also track the
   next operation - for most operations this is nothing, but to do a Validate
   or Commit we need to do an EditConfig first, under the covers.
-}


type alias Model =
    { xml : String
    , lastOp : NetconfOp
    , nextOp : NextOp
    , samples : Samples.State
    , result : RpcData String
    , connectionUp : Bool
    , endpoint : Endpoint
    }


type NextOp
    = NoneNext
    | ValidateNext
    | CommitNext


type NetconfOp
    = Get String
    | GetConfig String
    | EditConfig String
    | Validate
    | Commit



{-
   Messages
-}


type Msg
    = UpdateXMLMsg String
    | NetconfOpMsg NetconfOp
    | LoadMsg String
    | SamplesMsg Samples.Msg



{- Requests outbound to the server -}


type Request
    = NetconfReq NetconfOp
    | PersistSaveReq (Dict String String)
    | PersistLoadReq
    | StartFeatureReq



{-
   Notifications inbound from the server
-}


type Notification
    = NetconfNfn (RpcData String)
    | PersistLoadNfn (Dict String String)
    | ConStateNfn Bool
