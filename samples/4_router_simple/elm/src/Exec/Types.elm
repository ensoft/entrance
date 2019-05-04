module Exec.Types exposing (Model, Msg(..))

{-| Types for CLI exec sub-app
-}

import EnTrance.Channel as Channel
import EnTrance.Types exposing (RpcData)



{- Model -}


type alias Model =
    { cli : String
    , result : RpcData String
    , connectionIsUp : Bool
    , sendPort : Channel.SendPort Msg
    }



{- Messages -}


type Msg
    = UpdateCLI String
    | Exec
    | ExecResult (RpcData String)
    | ConnectionIsUp Bool
    | ChannelIsUp Bool
    | Error String
