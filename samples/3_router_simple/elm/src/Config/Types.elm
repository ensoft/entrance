module Config.Types exposing (..)

{-|
   Types for the CLI config feature
-}

import Dict exposing (Dict)
import EnTrance.Endpoint exposing (Endpoint, RpcData)
import Utils.Samples as Samples
import Config.Munge as Munge


{-
   Model
-}


type alias Model =
    { config : String
    , checkOnly : Bool
    , rawView : Bool
    , commitResult : RpcData String
    , failuresResult : RpcData String
    , mungedFailures : Munge.Errors
    , samples : Samples.State
    , connectionUp : Bool
    , endpoint : Endpoint
    }



{-
   Messages
-}


type Msg
    = CommitMsg Bool
    | UpdateConfigMsg String
    | LoadMsg String
    | SamplesMsg Samples.Msg
    | RawViewMsg Bool



{-
   Requsts outbound to the server
-}


type Request
    = ConfigLoadReq String
    | ConfigCommitReq Bool
    | ConfigGetFailuresReq
    | PersistSaveReq (Dict String String)
    | PersistLoadReq
    | StartFeatureReq



{-
   Notifications received from server
-}


type Notification
    = ConfigLoadNfn (RpcData String)
    | ConfigCommitNfn (RpcData String)
    | ConfigGetFailuresNfn (RpcData String)
    | PersistLoadNfn (Dict String String)
    | ConStateNfn Bool
