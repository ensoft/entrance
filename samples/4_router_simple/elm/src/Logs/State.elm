port module Logs.State exposing
    ( clearAll
    , initialModel
    , subscriptions
    , update
    )

{-| State handling for logs feature
-}

import EnTrance.Channel as Channel
import EnTrance.Feature.Target.Syslog as Syslog exposing (Syslog(..))
import EnTrance.Types exposing (MaybeSubscribe(..))
import Json.Decode exposing (Decoder)
import Logs.Types exposing (Model, Msg(..))
import Response exposing (pure)
import Utils.Inject as Inject
import Utils.LoL as LoL exposing (LoL)
import Utils.Toast as Toast



-- Create channel ports


port syslogSend : Channel.SendPort msg


port syslogRecv : Channel.RecvPort msg


port syslogIsUp : Channel.IsUpPort msg


{-| Initial state
-}
initialModel : Model
initialModel =
    { logs = empty
    , sendPort = syslogSend
    }


empty : LoL a
empty =
    LoL.empty 1.0


{-| Subscriptions
-}
subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ syslogIsUp ChannelIsUp
        , Channel.sub syslogRecv Error decoders
        ]


{-| Decoders for all the notifications we can receive
-}
decoders : List (Decoder Msg)
decoders =
    [ Syslog.decode GotLog ]


{-| Update
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotLog (Syslog logMsg timestamp) ->
            let
                maybeToast =
                    if String.contains "%MGBL-CONFIG-6-DB_COMMIT : " logMsg then
                        Toast.Info "New configuration commit point" ""
                            |> Inject.Toast
                            |> Inject.send

                    else
                        pure
            in
            { model | logs = LoL.add logMsg timestamp model.logs }
                |> maybeToast

        ChannelIsUp True ->
            -- Just subscribe to regular syslogs without filters or debug
            Syslog.start IgnoreConState [] []
                |> Channel.send model

        ChannelIsUp False ->
            pure model

        Error error ->
            Inject.send (Inject.Error "logs" error) model



{-
   User clicked the "Clear" button
-}


clearAll : Model -> Model
clearAll model =
    { model | logs = empty }
