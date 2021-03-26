module Types exposing (Model, Msg(..))

import EnTrance.Channel as Channel
import EnTrance.Types exposing (RpcData)
import RemoteData exposing (WebData)



-- MODEL


type alias Model =
    { runningFromStatic : Bool
    , editText : String
    , notes : List String
    , errors : List String
    , result : RpcData ()
    , staticData : WebData (List String)
    , connected : Bool
    , sendPort : Channel.SendPort Msg
    }



-- MESSAGES


type Msg
    = Input String
    | Save
    | ClearAll
    | Loaded (List String)
    | Saved (RpcData ())
    | ChannelIsUp Bool
    | Error String
    | StaticData (WebData (List String))
