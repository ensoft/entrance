module Utils.Toast exposing (Toast(..), config, decoder, encode, view)

{-| Adapts the generic Toasty package for our specific use with Bootstrap
-}

import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Toasty


{-| Type for toasts. Each severity has two strings: a title and a message body
-}
type Toast
    = Info String String
    | Success String String
    | Warning String String
    | Danger String String


{-| Configuraton options
-}
config : Toasty.Config msg
config =
    Toasty.config
        |> Toasty.transitionOutDuration 500
        |> Toasty.delay 5000


{-| View
-}
view : Toast -> Html msg
view toast =
    let
        ( severity, title, message ) =
            case toast of
                Info t m ->
                    ( Card.info, t, m )

                Success t m ->
                    ( Card.success, t, m )

                Warning t m ->
                    ( Card.warning, t, m )

                Danger t m ->
                    ( Card.danger, t, m )

        maybeMessage =
            if message /= "" then
                [ Block.text [] [ text message ] ]

            else
                []
    in
    div [ class "toasts" ]
        [ Card.config [ severity ]
            |> Card.block []
                (Block.titleH6 [] [ text title ] :: maybeMessage)
            |> Card.view
        ]



-- @@@@


encode : Toast -> Value
encode toast =
    case toast of
        Info title body ->
            enc "info" title body

        Success title body ->
            enc "success" title body

        Warning title body ->
            enc "warning" title body

        Danger title body ->
            enc "danger" title body


enc : String -> String -> String -> Value
enc severity title body =
    Encode.object
        [ ( "severity", Encode.string severity )
        , ( "title", Encode.string title )
        , ( "body", Encode.string body )
        ]


decoder : Decoder Toast
decoder =
    decodeSev
        |> Decode.andThen
            (\sev ->
                Decode.map2 sev
                    (Decode.field "title" Decode.string)
                    (Decode.field "body" Decode.string)
            )


decodeSev : Decoder (String -> String -> Toast)
decodeSev =
    Decode.field "severity" Decode.string
        |> Decode.andThen decodeConstructor


decodeConstructor : String -> Decoder (String -> String -> Toast)
decodeConstructor severity =
    case severity of
        "info" ->
            Decode.succeed Info

        "success" ->
            Decode.succeed Success

        "warning" ->
            Decode.succeed Warning

        "danger" ->
            Decode.succeed Danger

        other ->
            Decode.fail ("Bad severity: " ++ other)
