module EnTrance.Ping
    exposing
        ( State
        , Msg
        , displayWarning
        , init
        , subscriptions
        , websocketUp
        , update
        , pongNotification
        )

{-| Monitor liveness of the server, and warn the user if it goes away or
becomes unresponsive.

@docs State
@docs Msg
@docs displayWarning
@docs init
@docs subscriptions
@docs websocketUp
@docs update
@docs pongNotification
-}

import Time exposing (Time)
import EnTrance.Endpoint as Endpoint exposing (Endpoint)
import EnTrance.Internal exposing (globalEndpointName)


{-| Opaque state for the ping functionality
-}
type alias State =
    { connectionStarted : Bool
    , stopMonitoring : Bool
    , lastTick : Time
    , lastPingReceivedAt : Time
    , displayWarning : Bool
    , endpoint : Endpoint
    }


{-| Should a warning be displayed to the user, indicating that connectivity
with the server is impaired, and the app may not function correctly?
-}
displayWarning : State -> Bool
displayWarning =
    .displayWarning



-- Timeout : 3 * ping interval


timeout : Time
timeout =
    3 * Time.second


{-| Opaque message type
-}
type Msg
    = TickMsg Time
    | StopMonitoringMsg



{-
   State handling
-}


{-| Initial state. Requires a websocket
-}
init : String -> State
init websocket =
    State False
        False
        0
        0
        False
        (Endpoint.named globalEndpointName websocket)


{-| Subscriptions
-}
subscriptions : State -> Sub Msg
subscriptions state =
    if state.stopMonitoring then
        -- We've been actively dismissed by the user, so stop cluttering up
        -- the debugger
        Sub.none
    else
        Time.every Time.second TickMsg


{-| Actions when websocket connectivity established
-}
websocketUp : State -> ( State, Cmd msg )
websocketUp state =
    pure { state | connectionStarted = True }


{-| Handle ping-specific messages
-}
update : Msg -> State -> ( State, Cmd msg )
update msg state =
    case msg of
        TickMsg now ->
            let
                -- If we've just started out, then consider ourselves to have
                -- just received a successful ping response from the server, to
                -- avoid immediately throwing up the warning. That gives
                -- us three seconds to establish ping connectivity
                lastPingReceivedAt =
                    if state.lastPingReceivedAt == 0 then
                        now
                    else
                        state.lastPingReceivedAt

                -- Throw up the message if we've timed out, and haven't opted
                -- out of monitoring
                displayWarning =
                    (now - lastPingReceivedAt > timeout)
                        && not state.stopMonitoring

                -- Only start sending pings once the connection has initially
                -- established, to avoid filling the websocket buffer
                cmd =
                    if state.connectionStarted then
                        sendPing state.endpoint
                    else
                        Cmd.none
            in
                ( { state
                    | lastTick = now
                    , lastPingReceivedAt = lastPingReceivedAt
                    , displayWarning = displayWarning
                  }
                , cmd
                )

        StopMonitoringMsg ->
            pure { state | stopMonitoring = True, displayWarning = False }


{-| "pong" notification received
-}
pongNotification : State -> State
pongNotification state =
    { state | lastPingReceivedAt = state.lastTick }



-- Helper functions


sendPing : Endpoint -> Cmd msg
sendPing endpoint =
    Endpoint.request "ping"
        |> Endpoint.sendRaw endpoint


pure : State -> ( State, Cmd msg )
pure state =
    ( state, Cmd.none )
