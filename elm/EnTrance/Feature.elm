module EnTrance.Feature
    exposing
        ( start
        , stop
        , MaybeSubscribe(..)
        , decodeConnectionState
        )

{-| Helper functionality for controlling dynamic features on the server.

See the EnTrance design notes document for background on dynamic features.

@docs start
@docs stop
@docs MaybeSubscribe
@docs decodeConnectionState
-}

import Json.Decode as Decode exposing (Decoder)
import EnTrance.Endpoint as Endpoint


{-| Create a `start_feature` request.

```elm
    startFeature "cli_exec" SubscribeToConState
    |> Endpoint.addTarget "router1"
    |> Endpoint.send model
```
-}
start : String -> MaybeSubscribe -> Endpoint.Params
start feature subscribe =
    let
        bool =
            case subscribe of
                SubscribeToConState ->
                    True

                IgnoreConState ->
                    False
    in
        Endpoint.request "start_feature"
            |> Endpoint.addString "feature" feature
            |> Endpoint.addBool "con_state_subscribe" bool


{-| Create a `stop_feature` request, for a given feature and target.
Arguments:

- the feature name to stop
- the target to use (or `defaultTarget` if irrelevant)
- a function that will actually create a request

```elm
    stopFeature "cli_exec"
    |> Endpoint.addTarget "router1"
    |> Endpoint.send model
```
-}
stop : String -> Endpoint.Params
stop feature =
    Endpoint.request "stop_feature"
        |> Endpoint.addString "feature" feature


{-| So-called "target features" typically include a connection to some remote
entity, that can be up or down. This type enables the client to indicate whether
or not it is subscribing to notifications of these up/down transitions, as well
as starting the feature itself.
-}
type MaybeSubscribe
    = SubscribeToConState
    | IgnoreConState


{-| Decode a `connection_state` notification, when these are
requested (using [SubscribeToConState](#MaybeSubscribe)). The
first parameter is the feature name.
-}
decodeConnectionState : String -> Decoder Bool
decodeConnectionState desiredFeature =
    let
        resolveBool ( foundFeature, state ) =
            if foundFeature == desiredFeature then
                Decode.succeed state
            else
                Decode.fail
                    ("Can't decode connection state for feature "
                        ++ foundFeature
                        ++ ", was expecting "
                        ++ desiredFeature
                    )
    in
        Decode.map2 (,)
            (Decode.field "feature" Decode.string)
            (Decode.field "state_is_up" Decode.bool)
            |> Decode.andThen resolveBool
