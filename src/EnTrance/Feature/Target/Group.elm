module EnTrance.Feature.Target.Group exposing
    ( start
    , startWithParent
    , stop
    , decodeIsUp
    )

{-| Target groups - see [here](EnTrance-Feature-Target) for an extended explanation.

@docs start
@docs startWithParent
@docs stop
@docs decodeIsUp

-}

import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (MaybeSubscribe(..))
import Json.Decode as Decode exposing (Decoder)


{-| Name of the feature
-}
target_group : String
target_group =
    "target_group"


{-| Create a target group.

This is an async request - use the connection state notifications to track
progress.

-}
start : MaybeSubscribe -> Request
start =
    Gen.start target_group


{-| Create a target group with specified parent group. This is an async
request - use the connection state notifications to track progress.
-}
startWithParent : String -> MaybeSubscribe -> Request
startWithParent parent maybeSub =
    Gen.start target_group maybeSub
        |> Request.addString "parent_target" parent


{-| Tear down a target group. This is an async request.
-}
stop : Request
stop =
    Gen.stop target_group


{-| Decode an up/down notification requested by passing
[SubscribeToConState](EnTrance-Types#MaybeSubscribe) to
[start](#start). Takes a message constructor.
-}
decodeIsUp : (Bool -> msg) -> Decoder msg
decodeIsUp makeMsg =
    Gen.decodeIsUp target_group
        |> Decode.map makeMsg
