module EnTrance.Feature.Target.Syslog exposing
    ( start
    , stop
    , Syslog(..)
    , decode
    , decodeIsUp
    )

{-| Listen for syslogs. Minimal example:

    import EnTrance.Channel as Channel
    import EnTrance.Feature.Router.Syslog as Syslog
    import EnTrance.Types exposing (MaybeSubscribe(..))

    Syslog.start IgnoreConState [] []
        |> Channel.send model

    Target.connect params
        |> Channel.send model

Once the connection is up, you will received a notification of type "syslog",
that can be decoded using [decode](#decode) into a [Syslog](#Syslog) type.


## Adding debug and/or filters

If you want to turn on one or more debugs, you can do that:

    debugs = ["debug sysdb access", "debug sysdb verification"]

    Syslog.start IgnoreConState debugs []
        |> Channel.send model

If you want to filter syslogs, you can provide a list of matching strings (in
fact Python regular expressions). If this is non-empty, then only syslogs
matching at least one filter will be sent.

    -- Just tell me about commits
    filters = ["%MGBL-CONFIG-6-DB_COMMIT"]

    Syslog.start IgnoreConState [] filters
        |> Channel.send model

And you can combine both debugs and filters:

    debugs = ["debug sysdb access", "debug sysdb verification"]
    filters = ["sysdb"]

    Syslog.start IgnoreConState debug filters
        |> Channel.send model

@docs start
@docs stop
@docs Syslog
@docs decode
@docs decodeIsUp

-}

import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (MaybeSubscribe)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Name of the feature
-}
syslog : String
syslog =
    "syslog"


{-| Start listening for syslogs on a single target. This is an async request -
use the connection state notifications to track progress.
-}
start : MaybeSubscribe -> List String -> List String -> Request
start maybeSub debugs filters =
    Gen.start syslog maybeSub
        |> Request.addValue "debugs" (Encode.list Encode.string debugs)
        |> Request.addValue "filters" (Encode.list Encode.string filters)


{-| A received syslog: a message and a timestamp.
-}
type Syslog
    = Syslog String Float


{-| Decode a syslog notification into a [Syslog](#Syslog). Takes a message
constructor.
-}
decode : (Syslog -> msg) -> Decoder msg
decode makeMsg =
    Gen.decodeNfn syslog
        (Decode.map2 Syslog
            (Decode.field "result" Decode.string)
            (Decode.field "time" Decode.float)
        )
        |> Decode.map makeMsg


{-| Stop listening for syslogs.
-}
stop : Request
stop =
    Gen.stop syslog


{-| Decode an up/down notification requested by passing
[SubscribeToConState](EnTrance-Types#MaybeSubscribe) to
[start](#start). Takes a message constructor.
-}
decodeIsUp : (Bool -> msg) -> Decoder msg
decodeIsUp makeMsg =
    Gen.decodeIsUp syslog
        |> Decode.map makeMsg
