module EnTrance.Persist exposing (save, load, decode)

{-| Helper functionality forusing the "persist" server feature. This is a
configured feature that allows the frontend app to save state across sessions,
stored on the server.

@docs save
@docs load
@docs decode
-}

import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import EnTrance.Endpoint as Endpoint


{-| Construct a `persist_save` request. Takes the data to persist, as a JSON-encoded value.
-}
save : Encode.Value -> Endpoint.Params
save data =
    Endpoint.request "persist_save"
        |> Endpoint.addValue "data" data


{-| Construct a `persist_load` request. Takes a default value to return if the server
has no persisted data, as a JSON-encoded value.
-}
load : Encode.Value -> Endpoint.Params
load defaultData =
    Endpoint.request "persist_load"
    |> Endpoint.addValue "default" defaultData
    


{-| Decode a `data` notification (eg in response to a 'load' request).

The caller should pass in a decoder for the expected data type.
-}
decode : Decoder data -> Decoder data
decode decoder =
    Decode.field "data" decoder
