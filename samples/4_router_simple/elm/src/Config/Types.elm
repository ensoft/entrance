module Config.Types exposing
    ( Model
    , Msg(..)
    )

{-| Types for the CLI config feature
-}

import EnTrance.Channel as Channel
import EnTrance.Feature.Target.Config as Config
import EnTrance.Types exposing (RpcData)
import Utils.Samples as Samples


{-| Model
-}
type alias Model =
    { config : String
    , onlyCheck : Bool
    , rawView : Bool
    , commitResult : RpcData String
    , failuresResult : RpcData String
    , failures : List Config.Failed
    , samples : Samples.State
    , connectionIsUp : Bool
    , sendPort : Channel.SendPort Msg
    }


{-| Messages
-}
type Msg
    = CommitMsg Bool
    | UpdateConfigMsg String
    | LoadMsg String
    | SamplesMsg Samples.Msg
    | RawViewMsg Bool
    | ChannelIsUp Bool
    | Error String
      -- notifications received from server
    | ConfigLoaded (RpcData String)
    | ConfigCommitted (RpcData String)
    | ConfigGotFailures (RpcData String)
    | ConfigIsUp Bool
    | PersistLoaded Samples.Data
