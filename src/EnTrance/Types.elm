module EnTrance.Types exposing
    ( RpcData
    , MaybeSubscribe(..)
    )

{-| This module contains a few common types, that can be safely imported
unqualified anywhere.


## Handling replies to RPC requests

The EnTrance RPC semantics specify that an RPC request gets a single reply
notification: either a success reply (of whatever type is specified for that
interaction) or a failure message (of type String). `RpcData` is a handy
specialisation of
[RemoteData](https://package.elm-lang.org/packages/krisajenkins/remotedata/latest/RemoteData#RemoteData)
for this case, where the error is always `String`.

One mental model is to think of how many conceptual progress bars your UI
should have - ie how many independent operations can go on, where the user
might care about how long they take, or whether they succeeded or failed. You
probably want an `RpcData` for each of those in your model.

@docs RpcData


## Getting up/down notifications

@docs MaybeSubscribe

-}

import RemoteData exposing (RemoteData(..))


{-| Specialisation of `RemoteData` to a `String` error type.
-}
type alias RpcData reply =
    RemoteData String reply


{-| So-called "target features" typically include a connection to some remote
entity, that can be up or down. This type enables the client to indicate whether
or not it is subscribing to notifications of these up/down transitions, as well
as starting the feature itself.

Note that the state subscriptions here are simplified to "up" or "down", and
are suitable for basic things such as disabling buttons when down. A vastly
more nuanced notion of state is available for
[connections](EnTrance-Feature-Target-Connection#State).

-}
type MaybeSubscribe
    = SubscribeToConState
    | IgnoreConState
