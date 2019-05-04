module Netconf.Types exposing (Model, Msg(..), NextOp(..))

{-| Netconf types
-}

import EnTrance.Channel as Channel
import EnTrance.Feature.Target.Netconf as Netconf
import EnTrance.Types exposing (RpcData)
import Utils.Samples as Samples


{-| Model. We keep track of the last Netconf operation to be initiated, so
we can report the success/failure state meaningfully. We also track the
next operation - for most operations this is nothing, but to do a Validate
or Commit we need to do an EditConfig first, under the covers.
-}
type alias Model =
    { xml : String
    , lastOp : Netconf.Op
    , nextOp : NextOp
    , samples : Samples.State
    , result : RpcData String
    , connectionIsUp : Bool
    , sendPort : Channel.SendPort Msg
    }


type NextOp
    = NoneNext
    | ValidateNext
    | CommitNext


{-| Messages
-}
type Msg
    = UpdateXML String
    | DoNetconfOp Netconf.Op
    | Loaded String
    | SamplesMsg Samples.Msg
    | DidNetconfOp (RpcData String)
    | PersistLoaded Samples.Data
    | ConnectionIsUp Bool
    | ChannelIsUp Bool
    | Error String
