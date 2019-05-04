module ReadDir exposing
    ( Directory
    , Entry
    , EntryType(..)
    , readDir
    , decodeReadDir
    )

{-| This module provides a client-side typesafe interface to the `read_dir`
server-side feature, that lists the contents of a directory from the server.

The feature is bespoke to this sample app (see `svr/run.py` for the other half)
but this module is written to be standalone, and can be re-used as-is.


# Result type

@docs Directory
@docs Entry
@docs EntryType


# Building requests and decoding replies

@docs readDir
@docs decodeReadDir

-}

import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (RpcData)
import Json.Decode as Decode exposing (Decoder)


{-| The result of listing the contents of a server-side directory: the path of
the directory, and a list of entries.
-}
type alias Directory =
    { fullPath :
        String
    , entries : List Entry
    }


{-| A single directory entry: a name and a type
-}
type alias Entry =
    { name : String
    , entryType : EntryType
    }


{-| The type of a single directory entry: a file, another directory, or
anything else (eg a device or fifo).
-}
type EntryType
    = File
    | Dir
    | Special


{-| Request to read a directory
-}
readDir : String -> Request
readDir path =
    Request.new "read_dir"
        |> Request.addString "path" path


{-| Decode notifications from the server
-}
decodeReadDir : (RpcData Directory -> msg) -> Decoder msg
decodeReadDir makeMsg =
    Decode.map2 Directory
        (Decode.field "full_path" Decode.string)
        (Decode.field "entries" decodeEntries)
        |> Gen.decodeRpc "read_dir"
        |> Decode.map makeMsg


decodeEntries : Decoder (List Entry)
decodeEntries =
    Decode.map2 Entry
        (Decode.field "name" Decode.string)
        (Decode.field "type" decodeEntryType)
        |> Decode.list


decodeEntryType : Decoder EntryType
decodeEntryType =
    let
        parse str =
            case str of
                "file" ->
                    Decode.succeed File

                "dir" ->
                    Decode.succeed Dir

                "special" ->
                    Decode.succeed Special

                other ->
                    Decode.fail ("Can't parse dir entry type " ++ other)
    in
    Decode.string
        |> Decode.andThen parse
