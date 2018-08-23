module Utils.Extra.Json exposing (..)

{-| Extra functions for JSON encoding/decoding
-}

import Dict
import Json.Encode as Encode


{-| Encode a Dict. Why isn't this in the standard Json.Encode module, given
there's a "dict" in Json.Decode? Well that's a pretty good question.
-}
encodeDict : Dict.Dict String String -> Encode.Value
encodeDict data =
    Dict.toList data
        |> List.map (\( k, v ) -> ( k, Encode.string v ))
        |> Encode.object
