module InsecureShell exposing
    ( CmdResult
    , cmd
    , decodeCmd
    )

{-| This module provides a client-side typesafe interface to the
`insecure_shell` server-side feature, that runs an arbitrary shell command on
the server and sends back the result.

The feature is bespoke to this sample app (see `svr/run.py` for the other half)
but this is written as a standalone module that can be re-used as is.

@docs CmdResult
@docs cmd
@docs decodeCmd

-}

import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (RpcData)
import Json.Decode as Decode exposing (Decoder)


{-| Result of a successful command: the stdout output, the stderr output, and
the exit code.
-}
type alias CmdResult =
    { stdout : String
    , stderr : String
    , exitCode : Int
    }


{-| Request to do a command.
-}
cmd : String -> Request
cmd shellCmd =
    Request.new "insecure_shell_cmd"
        |> Request.addString "cmd" shellCmd


{-| Decode notifications from the server. Takes a message constructor.
-}
decodeCmd : (RpcData CmdResult -> msg) -> Decoder msg
decodeCmd makeMsg =
    Gen.decodeRpc "insecure_shell_cmd" decodeResult
        |> Decode.map makeMsg


decodeResult : Decoder CmdResult
decodeResult =
    Decode.map3 CmdResult
        (Decode.field "stdout" Decode.string)
        (Decode.field "stderr" Decode.string)
        (Decode.field "exit_code" Decode.int)
