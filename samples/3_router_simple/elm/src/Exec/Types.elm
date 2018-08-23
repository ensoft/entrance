module Exec.Types exposing (..)

{-|
   Types for CLI exec sub-app
-}

import EnTrance.Endpoint exposing (Endpoint, RpcData)


{- Model -}


type alias Model =
    { cli : String
    , result : RpcData String
    , connectionUp : Bool
    , endpoint : Endpoint
    }



{- Messages -}


type Msg
    = ExecMsg
    | UpdateCLIMsg String



{- Requests outbound to the server -}


type Request
    = StartFeatureReq
    | CLIExecReq String



{- Notifications inbound from the server -}


type Notification
    = CLIExecNfn (RpcData String)
    | ConStateNfn Bool
