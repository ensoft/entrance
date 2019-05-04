module Types exposing (Model, Msg(..))

import EnTrance.Channel as Channel
import EnTrance.Types exposing (RpcData)



-- MODEL


type alias Model =
    { editText : String
    , notes : List String
    , errors : List String
    , result : RpcData ()
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
