module Logs.Types exposing (..)

{-|
   Types for log sub-app
-}

import EnTrance.Endpoint exposing (Endpoint)
import Utils.LoL exposing (..)


{-
   Model. The "Severity" determines the color. A "SimpleLog" is a simplified
   log entry that corresponds to a flat entry or an arrow in a sequence diagram.
-}


type alias Model =
    { logs : LoL String
    , endpoint : Endpoint
    }



{-
   Messages - actually none required, but leave a placeholder in to avoid
   re-plumbing if this is extended in any way
-}


type Msg
    = None



{-
   Requests outbound to the server
-}


type Request
    = StartFeatureReq (List String) (List String)



{-
   Notifications inbound from the server
-}


type Notification
    = LogNfn String Float
