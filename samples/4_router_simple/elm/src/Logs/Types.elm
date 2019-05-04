module Logs.Types exposing (Model, Msg(..))

{-| Types for log sub-app
-}

import EnTrance.Channel as Channel
import EnTrance.Feature.Target.Syslog exposing (Syslog)
import Utils.LoL exposing (LoL)



{-
   Model. The "Severity" determines the color. A "SimpleLog" is a simplified
   log entry that corresponds to a flat entry or an arrow in a sequence diagram.
-}


type alias Model =
    { logs : LoL String
    , sendPort : Channel.SendPort Msg
    }


{-| Messages
-}
type Msg
    = GotLog Syslog
    | ChannelIsUp Bool
    | Error String
