module Types exposing
    ( Model
    , Msg(..)
    )

import EnTrance.Channel as Channel
import EnTrance.Types exposing (RpcData)
import ReadDir exposing (Directory)



-- MODEL


type alias Model =
    { dirText : String
    , currentDir : String
    , result : RpcData Directory
    , history : List String
    , connected : Bool
    , errors : List String
    , sendPort : Channel.SendPort Msg
    }



-- MESSAGES


type Msg
    = Input String
    | GotoDir String
    | GoUp
    | GoBack
    | ReceivedDir (RpcData Directory)
    | ChannelIsUp Bool
    | Error String
