module Utils.Inject exposing (..)

{-| Inject messages back into the event loop as Cmds
-}

import Process
import Task
import Time exposing (Time)
import TopLevel.Types as TopLevel
import Utils.Toast exposing (Toast)


{-
   Inject a message as a command. Don't use unless you know why you really need it
-}


msg : msg -> Cmd msg
msg msg =
    Task.perform identity (Task.succeed msg)



{-
   Wait for a period of time before doing the injection
-}


msgAfter : Time -> msg -> Cmd msg
msgAfter time msg =
    Process.sleep time
        |> Task.andThen (always <| Task.succeed msg)
        |> Task.perform identity


{-| Add a toast
-}
toast : Toast -> Cmd TopLevel.Msg
toast toast =
    msg (TopLevel.AddToast toast)
