port module Utils.Inject exposing
    ( Msg(..)
    , send
    , sub
    )

{-| Inject messages back into the event loop as Cmds
-}

import EnTrance.Channel as Channel
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Utils.Toast as Toast exposing (Toast)


port injectSend : Channel.InjectSendPort msg


port injectRecv : Channel.InjectRecvPort msg


send : Msg -> model -> ( model, Cmd msg )
send msg model =
    ( model, (injectSend << encode) msg )


sub : (Msg -> msg) -> Sub msg
sub mkMsg =
    injectRecv (mkMsg << decode)


type Msg
    = Toast Toast
    | Error String String


encode : Msg -> Value
encode injectMsg =
    case injectMsg of
        Toast toast ->
            Encode.object
                [ ( "type", Encode.string "Toast" )
                , ( "toast", Toast.encode toast )
                ]

        Error subsys error ->
            Encode.object
                [ ( "type", Encode.string "Error" )
                , ( "subsys", Encode.string subsys )
                , ( "error", Encode.string error )
                ]


decode : Value -> Msg
decode json =
    case Decode.decodeValue decoder json of
        Ok msg ->
            msg

        Err err ->
            Error "inject"
                ("Problem decoding Msg: "
                    ++ Decode.errorToString err
                )


decoder : Decoder Msg
decoder =
    Decode.field "type" Decode.string
        |> Decode.andThen decodeType


decodeType : String -> Decoder Msg
decodeType injectType =
    case injectType of
        "Toast" ->
            Decode.field "toast" Toast.decoder
                |> Decode.map Toast

        "Error" ->
            Decode.map2 Error
                (Decode.field "subsys" Decode.string)
                (Decode.field "error" Decode.string)

        other ->
            Decode.fail ("Bad InjectType: " ++ other)
