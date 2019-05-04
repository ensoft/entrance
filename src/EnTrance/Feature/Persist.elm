module EnTrance.Feature.Persist exposing
    ( save
    , decodeSave
    , saveAsync
    , load
    , decodeLoad
    )

{-| The `persist` feature provides the ability for any channel to save some
data (in JSON format) on the server, and read it back later. This is a basic
service intended for slowly-changing small data, not a database.

If multiple browser instances of the same app are open, then saving from one
will trigger a notification (decoded with [decodeLoad](#decodeLoad)) to all the
others, to keep them somewhat in step. If two different changes are saved in
close succession, one of them will win, and one will be lost.


# Saving data on the server

@docs save
@docs decodeSave
@docs saveAsync


# Loading data from the server

@docs load
@docs decodeLoad

-}

import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (RpcData)
import Json.Decode as Decode exposing (Decoder, Value)


{-| Save the provided JSON data on the server, and get an RPC response when
complete.
-}
save : Value -> Request
save data =
    Request.new "persist_save_sync"
        |> Request.addValue "data" data


{-| Decode the reply to a `save` request. The `Success` payload is just `()`.
Failures should be very uncommon. Takes a message contstructor.
-}
decodeSave : (RpcData () -> msg) -> Decoder msg
decodeSave makeMsg =
    Gen.decodeRpc "persist_save_sync" (Decode.succeed ())
        |> Decode.map makeMsg


{-| Save the provided JSON data on the server, as an async unacknowledged
operation. This may be suitable for some non-critical things (eg preferences)
where failures don't need UI.
-}
saveAsync : Value -> Request
saveAsync data =
    Request.new "persist_save_async"
        |> Request.addValue "data" data


{-| Construct a `persist_load` request: load the data for this channel from the
server, or return the default value provided if there isn't any yet.

This also subscribes this channel to future updates, so that if another browser
instance for this channel changes the data we just asked for, we'll get another
notification (decodable with [decodeLoad](#decodeLoad)]) with the updated data.

-}
load : Value -> Request
load defaultData =
    Request.new "persist_load"
        |> Request.addValue "default" defaultData


{-| Decode the response to a `persistLoad` request - either right after a
[load](#load) request, or later in the lifetime of the app, if another browser
instance later changes the data we've requested.

Takes a decoder for the actual data payload and a message constructor.

-}
decodeLoad : Decoder data -> (data -> msg) -> Decoder msg
decodeLoad decodeResult makeMsg =
    Gen.decodeNfn "persist_load"
        (Decode.field "data" decodeResult)
        |> Decode.map makeMsg
