module EnTrance.Feature.Target.CLI exposing
    ( exec
    , decodeExec
    , start
    , stop
    , decodeIsUp
    )

{-| Good ol' CLI prompt interactions. Minimal example:

    import EnTrance.Channel as Channel
    import EnTrance.Feature.Dynamic exposing (MaybeSubscribe(..))
    import EnTrance.Feature.Target as Target
    import EnTrance.Feature.Target.CLI as CLI

    CLI.start SubscribeToConState
        |> Channel.send model

    Target.connect params
        |> Channel.send model

    --
    -- Back in your update function, after you get a notification saying
    -- the connection state is `Connected`:
    --
    CLI.exec "show version"
        |> Channel.sendSimpleRpc model

Once the CLI command is executed, your update function will get a notification
you decode using [decode](#decode).

@docs exec
@docs decodeExec


# Starting and stopping

@docs start
@docs stop
@docs decodeIsUp

-}

import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (MaybeSubscribe, RpcData)
import Json.Decode as Decode exposing (Decoder)


{-| Name of the feature
-}
cli_exec : String
cli_exec =
    "cli_exec"


{-| Send a CLI command, and get back the result.
-}
exec : String -> Request
exec command =
    Request.new cli_exec
        |> Request.addString "command" command


{-| Decode the reply notification to an `exec` request. Takes a message
constructor.
-}
decodeExec : (RpcData String -> msg) -> Decoder msg
decodeExec makeMsg =
    Gen.decodeRpc cli_exec Decode.string
        |> Decode.map makeMsg


{-| Start a CLI feature instance. This represents the option to connect to one
router. This is an async request - use the connection state notifications to
track progress.
-}
start : MaybeSubscribe -> Request
start =
    Gen.start cli_exec


{-| Stop a CLI feature instance. This is an async request.
-}
stop : Request
stop =
    Gen.stop cli_exec


{-| Decode an up/down notification requested by passing
[SubscribeToConState](EnTrance-Types#MaybeSubscribe) to
[start](#start). Takes a message constructor.
-}
decodeIsUp : (Bool -> msg) -> Decoder msg
decodeIsUp makeMsg =
    Gen.decodeIsUp cli_exec
        |> Decode.map makeMsg
