module Types exposing
    ( Model
    , Msg(..)
    )

import EnTrance.Channel as Channel
import EnTrance.Types exposing (RpcData)
import InsecureShell exposing (CmdResult)



-- MODEL


type alias Model =
    { cmdText : String
    , result : RpcData CmdResult
    , isUp : Bool
    , errors : List String
    , sendPort : Channel.SendPort Msg
    }



-- MESSAGES


type Msg
    = Input String
    | RunCmd
    | GotResult (RpcData CmdResult)
    | ChannelIsUp Bool
    | Error String
