port module Utils.Inject exposing
    ( Msg(..)
    , send
    , sub
    )

{-| This module permits any update function to inject Toast or Error messages
back into the top-level event handler, as Cmds. (This uses the EnTrance [inject
pseudo-channel](https://package.elm-lang.org/packages/ensoft/entrance/latest/EnTrance-Channel#the-inject-pseudo-channel)
under the covers.)

(There are other ways of doing this (such as having the sub-app update function
return more than just a vanilla `(Model, Cmd Msg)` pair), and you should
consider the pros/cons of each for your application. This option chooses to
concentrate magic into one small place, leaving the rest of the app looking
"normal".)

-}

import EnTrance.Channel as Channel
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Utils.Toast as Toast exposing (Toast)


{-| The types of message that we can loop back to the top level: either Toasts
(pop-up notifications) or Errors (rare major problems).
-}
type Msg
    = Toast Toast
    | Error String String


{-| Send either a Toast or Error message to the top level.
-}
send : Msg -> model -> ( model, Cmd msg )
send msg model =
    ( model, (injectSend << encode) msg )


{-| From the top level, subscribe for received Toast/Error messages.
-}
sub : (Msg -> msg) -> Sub msg
sub mkMsg =
    injectRecv (mkMsg << decode)



----------------------------------------------------------------------
--
-- Internal implementation
--
----------------------------------------------------------------------


{-| Ports - the app can have one pair of these globally
-}
port injectSend : Channel.InjectSendPort msg


port injectRecv : Channel.InjectRecvPort msg


{-| Encode a Msg into Json
-}
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


{-| Decode Json into a Msg
-}
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
