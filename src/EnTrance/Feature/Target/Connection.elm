module EnTrance.Feature.Target.Connection exposing
    ( Params
    , AuthType(..)
    , State(..)
    , GroupState
    , decodeState
    , decodeGroupState
    , decodeParams
    , encodeParams
    )

{-| Connection management.


# Connection details

@docs Params
@docs AuthType


# Connection state

@docs State
@docs GroupState


# Encoders and decoders

@docs decodeState
@docs decodeGroupState
@docs decodeParams
@docs encodeParams

-}

import EnTrance.Feature.Gen as Gen
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Everything needed to connect to a protocol peer.

  - `host`: IP address or hostname of the peer
  - `username`: username for authentication
  - `secret`: either a plaintext password, or the pathame of a file on the
    EnTrance server containing an ssh key
  - `authType`: which of the password/ssh key options should be used
  - `sshPort`: which port to connect to on the peer for ssh operations
  - `netconfPort`: which port to connect to on the peer for Netconf operations

If you aren't going to use eg Netconf, then it doesn't matter what value is
provided for `netconfPort`.

-}
type alias Params =
    { host : String
    , username : String
    , secret : String
    , authType : AuthType
    , sshPort : String
    , netconfPort : String
    }


{-| Whether the `secret` part of `Params` should be interpreted as a password,
or a pathname for a file on the EnTrance server containing an ssh key.
-}
type AuthType
    = Password
    | SshKey


{-| Abstracted description of the state of protocol connection. Later
constructors are considered "worse" than earlier (eg `FailedToConnect` is worse
than `Connected`) when multiple connection states are aggregated via [target
groups](EnTrance-Feature-Target).

The states involving failure include a `String` giving more details.

-}
type State
    = Disconnected
    | Connected
    | FailureWhileDisconnecting String
    | Finalizing
    | Connecting
    | Disconnecting
    | ReconnectingAfterFailure String
    | FailedToConnect String


{-| An aggregate state notification received for a target, or target group. You
receive one of these when you used
[SubscribeToConState](EnTrance-Types#MaybeSubscribe) when starting a
target or target group, and one of the underlying connections just changed
state.

  - `groupState`: the new overall connection state
  - `childName`: the name of the child whose state just changed
  - `childState`: the new state of the changed child
  - `timestamp`: a "HH:MM:SS" string giving a timestamp

-}
type alias GroupState =
    { groupState : State
    , childName : String
    , childState : State
    , timestamp : String
    }


{-| JSON decoder for [GroupState](#GroupState). Takes a message constructor.
-}
decodeGroupState : (GroupState -> msg) -> Decoder msg
decodeGroupState makeMsg =
    Gen.decodeNfn "connection_state"
        (Decode.map4 GroupState
            (Decode.field "state" decodeState)
            (Decode.field "child" Decode.string)
            (Decode.field "child_state" decodeState)
            (Decode.field "timestamp" Decode.string)
        )
        |> Decode.map makeMsg


{-| JSON decoder for [connection state](#State).
-}
decodeState : Decoder State
decodeState =
    let
        connState str err =
            case str of
                "DISCONNECTED" ->
                    Decode.succeed Disconnected

                "CONNECTED" ->
                    Decode.succeed Connected

                "FAILURE_WHILE_DISCONNECTING" ->
                    Decode.succeed (FailureWhileDisconnecting err)

                "FINALIZING" ->
                    Decode.succeed Finalizing

                "CONNECTING" ->
                    Decode.succeed Connecting

                "DISCONNECTING" ->
                    Decode.succeed Disconnecting

                "RECONNECTING_AFTER_FAILURE" ->
                    Decode.succeed (ReconnectingAfterFailure err)

                "FAILED_TO_CONNECT" ->
                    Decode.succeed (FailedToConnect err)

                unknown ->
                    Decode.fail ("Unknown connection state: " ++ unknown)
    in
    Decode.map2 connState
        (Decode.field "state" Decode.string)
        (Decode.field "error" Decode.string)
        |> Decode.andThen identity


{-| JSON decoder for [connection params](#Params).
-}
decodeParams : Decoder Params
decodeParams =
    let
        authType authIsPassword =
            if authIsPassword then
                Password

            else
                SshKey
    in
    Decode.map6 Params
        (Decode.field "host" Decode.string)
        (Decode.field "username" Decode.string)
        (Decode.field "secret" Decode.string)
        (Decode.field "auth_is_password" (Decode.bool |> Decode.map authType))
        (Decode.field "ssh_port" Decode.string)
        (Decode.field "netconf_port" Decode.string)


{-| JSON encoder for [Params](#Params). This can be handy for, eg, persisting
connection settings.
-}
encodeParams : Params -> Encode.Value
encodeParams params =
    [ ( "host", Encode.string params.host )
    , ( "username", Encode.string params.username )
    , ( "secret", Encode.string params.secret )
    , ( "auth_is_password", Encode.bool (params.authType == Password) )
    , ( "ssh_port", Encode.string params.sshPort )
    , ( "netconf_port", Encode.string params.netconfPort )
    ]
        |> Encode.object
