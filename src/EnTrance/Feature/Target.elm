module EnTrance.Feature.Target exposing
    ( connect
    , disconnect
    , set
    , decode
    )

{-| EnTrance provides a rich set of functionality for interacting with multiple
simultaneous protocol peers (such as high-end routers). Understanding how to
use this requires the notion of a "target".

If you don't need to initiate simultaneous protocol sessions to multiple
peers, you can skip this module!


## Targets

The EnTrance abstraction for something like a router, to which protocol
sessions can be opened, is a _target_. A target is a string identifier, chosen
by your app, which disambiguates between multiple protocol endpoints. The name
itself doesn't matter - using `router1` and `router2` will have identical
semantics to `bill` and `ted`.

If your app talks only to one device at a time, you can just omit anything to
do with target names. For example, if you want to execute the CLI command `show
version` on a single router, you can just do this, without ever mentioning
target names at all:

    import EnTrance.Channel as Channel
    import EnTrance.Feature.Target as Target
    import EnTrance.Feature.Target.CLI as CLI
    import EnTrance.Types exposing (MaybeSubscribe(..))

    -- Start the CLI exec feature
    CLI.start SubscribeToConState
        |> Channel.send model

    -- Connect from the server to the target (the single router)
    Target.connect params
        |> Channel.send model

    -- Back in your update function, after you get a notification saying
    -- the connection state is `Connected`:
    CLI.exec "show version"
        |> Channel.sendSimpleRpc model

If you might talk to two or more devices, then you must assign your own
target names, and specify the appropriate one for every request. For example:

    -- Start the CLI exec feature for the target
    CLI.start SubscribeToConState
        |> Target.set "router1"
        |> Channel.send model

    -- Connect from the server to the target
    Target.connect params
        |> Target.set "router1"
        |> Channel.send model

    -- Back in your update function, after you get a notification saying
    -- the connection state is `Connected`:
    CLI.exec "show version"
        |> Target.set "router1"
        |> Channel.sendSimpleRpc model

The way the first option works, is that EnTrance silently assigns a default
target name for you (imaginatively called `defaultTarget`) unless you override
it, as in the second example.

Note that connections are initiated on a per-target basis, not a per-feature
basis. So `Target.connect` initiates outbound connections for all features for
the given target (default or specified).

@docs connect
@docs disconnect


## Connection state

A single protocol session has a unified abstraction of a [connection
state](EnTrance-Feature-Target-Connection#State) - eg `Connected`,
`Disconnecting`, or `FailedToConnect`. So whether you are talking Netconf over
SSH or gNMI over gPRC, you can have a unified user interface to show what's
working and what isn't.


## Target groups

If you have multiple protocol sessions to the same target (eg you might have
both [Netconf](EnTrance-Feature-Target-Netconf) and a
[Syslog](EnTrance-Feature-Target-Syslog) connections), then creating a [target
group](EnTrance-Feature-Target#Group) with the same target name as the Netconf
and Syslog feature provides an aggregate entity with two handy properties:

  - You can call `connect` and `disconnect` on the target group, and it will
    automatically invoke the connect/disconnect operation on everything in the
    group.

  - An aggregate connection state is maintained for the group, that enables you
    to easily present a more easily understood user interface. The aggregate state
    is essentially the "worst" state of anything in the group. So if any one
    session is in `FailedtoConnect` state, that's the state of the group. But if
    everything is `Connected`, then that's the state of the group. So this makes it
    easy to present a simplified state to the user.

This is so useful in practice that currently `connect` and `disconnect` are
exposed _only_ for groups. So if you have only a single Netconf session, for
example, you still have to create a group with the same target name, in order
to connect. File an issue if this actually causes problems. (This is a
side-effect of the server-side demux logic.)

For example, if you do this set of requests:

    import EnTrance.Feature.Target.CLI as CLI
    import EnTrance.Feature.Target.Syslog as Syslog
    import EnTrance.Feature.Target.Group as Group

    Group.start
        |> Channel.send model

    Syslog.start
        |> Channel.send model

    Netconf.start
        |> Channel.send model

then these will self-assemble into a hierarchy where the CLI and Netconf
features are children of the Group (because they all have the same target name,
namely `defaultTarget`):

```text
 Target-group    [ defaultTarget ]
     ├── Syslog  [ defaultTarget ]
     └── Netconf [ defaultTarget ]
```

That then means you can call `connect` or `disconnect` on
just the group, and the individual CLI/Netconf `connect`/`disconnect` calls are
handled for you, and you can also subscribe to the group connection state.


## Target group hierarchies

You can go further, and create arbitrary hierarchies of target groups. So if
you had Netconf and Syslog connections to a bunch of routers, themselves
grouped into "core" and "edge" groups, then EnTrance might tell you that all
the "core" routers are `Connected`, but the "edge" group is `Connecting` (if eg
one netconf connection to one edge router is `Connecting` but everything else
is `Connected`).

You invoke this hierarchy functionality simply by providing a "parent group"
when creating a new group - this slides the new group under the specified
parent. A target group without a parent is the root of its own sub-hierarchy.

For example, if you do this set of requests:

    Group.start
        |> Target.set "router1"
        |> Channel.send model

    Syslog.start
        |> Target.set "router1"
        |> Channel.send model

    Netconf.start
        |> Target.set "router1"
        |> Channel.send model

    Group.start
        |> Target.set "router2"
        |> Channel.send model

    Syslog.start
        |> Target.set "router2"
        |> Channel.send model

    Netconf.start
        |> Target.set "router2"
        |> Channel.send model

then these self-assemble into two isolated hierarchies, based on target name:

```text
 Target-group   [ router1 ]
    ├── Syslog  [ router1 ]
    └── Netconf [ router1 ]

 Target-group   [ router2 ]
    ├── Syslog  [ router2 ]
    └── Netconf [ router2 ]
```

If you create groups like this instead:

    Group.start
        |> Target.set "all-routers"
        |> Channel.send model

    Group.startWithParent "all-routers"
        |> Target.set "router1"
        |> Channel.send model

    Group.startWithParent "all-routers"
        |> Target.set "router2"
        |> Channel.send model

then you create an additional level of connection state summarisation:

```text
 Target-group            [ all-routers ]
     |
     ├── Target-group    [ router1 ]
     |       ├── Syslog  [ router1 ]
     |       └── Netconf [ router2 ]
     |
     └── Target-group    [ router2 ]
             ├── Syslog  [ router2 ]
             └── Netconf [ router2 ]
```


# Requests and Notifications

By default, all [Request](EnTrance-Request#Request)s have a default `target`
value, in order to keep a simple API for the vast majority of apps that are not
target aware.

If your app is target aware, then you can specify the intended target for each
request using `add`.

@docs set

Similarly, the standard notification decoders (eg
[Netconf.decodeRequest](EnTrance-Feature-Target-Netconf#decodeRequest)) decode
do not force the target into the API. If you app is target aware, you can
upgrade any of these decoders to one that also provides the relevant target
using `decode`.

@docs decode

-}

import EnTrance.Feature.Target.Connection as Connection
import EnTrance.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)


{-| Initiate connection requests for all features for a single target. If
you're just using the default target, to talk to a single peer device, then
just start one or more features, and then call this. eg for a single Netconf
session:

    Netconf.start
        |> Channel.send model

    Target.connect params
        |> Channel.send model

If you're handling multiple targets, then use
[addTarget](EnTrance-Request#addTarget). For example:

    Netconf.start
        |> Target.set "router1"
        |> Channel.send model

    Syslog.start
        |> Target.set "router1"
        |> Channel.send model

    Target.connect params
        |> Target.set "router1"
        |> Channel.send model

This is an async request - use the connection state notifications to track
progress.

-}
connect : Connection.Params -> Request
connect params =
    Request.new "connect"
        |> Request.addValue "params" (Connection.encodeParams params)
        -- In the future, there might be other options here (eg gRPC)
        -- but hardcode the only implemented option today, ie ssh.
        |> Request.addString "connection_type" "ssh"


{-| Initiate disconnect requests for all features with this target.

This is an async request - use the connection state notifications to track
progress.

-}
disconnect : Request
disconnect =
    Request.new "disconnect"


{-| Add a `target` parameter to a request.
-}
set : String -> Request -> Request
set target =
    Request.addString "target" target


{-| Extract the target from any notification. This turns the result of any
other decoder into a pair, where the first item is the target name.
-}
decode : Decoder a -> Decoder ( String, a )
decode decodeRest =
    let
        addTarget target =
            decodeRest
                |> Decode.map (\isUp -> ( target, isUp ))
    in
    Decode.field "target" Decode.string
        |> Decode.andThen addTarget
