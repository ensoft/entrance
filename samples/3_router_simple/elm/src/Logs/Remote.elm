module Logs.Remote exposing (..)

{-|
   Remote handling for the logs  feature
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import EnTrance.Endpoint as Endpoint
import EnTrance.Feature as Feature
import Logs.Types exposing (..)


{-| The endpoint name
-}
endpoint : String
endpoint =
    "logs"



{-
   Decode incoming JSON notifications
-}


nfnDecoder : Model -> String -> Decoder Notification
nfnDecoder _ nfnType =
    case nfnType of
        "syslog" ->
            Decode.map2 LogNfn
                (Decode.field "result" Decode.string)
                (Decode.field "time" Decode.float)

        unknown ->
            Decode.fail <| "Unknown logs nfn_type: " ++ unknown


{-| Send outgoing JSON requests. In fact only one!
-}
startSyslogFeature : Model -> List String -> List String -> ( Model, Cmd Msg )
startSyslogFeature model debugs filters =
    Feature.start "syslog" Feature.IgnoreConState
        |> Endpoint.addDefaultTarget
        |> Endpoint.addValue "debugs" (debugs |> List.map Encode.string |> Encode.list)
        |> Endpoint.addValue "filters" (filters |> List.map Encode.string |> Encode.list)
        |> Endpoint.send model
