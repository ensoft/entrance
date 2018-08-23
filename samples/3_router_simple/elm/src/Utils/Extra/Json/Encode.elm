module Utils.Extra.Json.Encode exposing (..)

{-| Extra functions for JSON encoding/decoding
-}

import Dict
import Json.Encode as Encode


{-| Encode a Dict. Why isn't this in the standard Json.Encode module, given
there's a "dict" in Json.Decode? Well that's a pretty good question.
-}
dict : Dict.Dict String String -> Encode.Value
dict data =
    Dict.toList data
        |> List.map (\( k, v ) -> ( k, Encode.string v ))
        |> Encode.object
