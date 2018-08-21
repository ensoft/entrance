module Types exposing (..)

{-| Model, Msg and Notification types
-}

import EnTrance.Endpoint exposing (Endpoint)
import EnTrance.Notification exposing (GlobalNfn)
import EnTrance.Ping as Ping


-- MODEL


type alias Model =
    { editText : String
    , notes : List String
    , errors : List String
    , connected : Bool
    , pingState : Ping.State
    , endpoint : Endpoint
    }



-- MESSAGES AND NOTIFICATIONS


type Msg
    = Input String
    | Save
    | ClearAll
    | ReceivedJSON String
    | PingMsg Ping.Msg


type Notification
    = Load (List String)
    | GlobalNfn GlobalNfn



-- DATA PROVIDED BY JAVASCRIPT


type alias Flags =
    { websocket : String }
