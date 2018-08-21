module EnTrance.Internal exposing (..)

{-| Private values used by both Endpoint and Notification
-}


{-| Name of the global Endpoint used for top-level handling
-}
globalEndpointName : String
globalEndpointName =
    "global"


{-| Prefix for JSON fail error messages due to a bad sequence number. These can
   be checked for using errorIsWarning, and simply logged rather than flagged up
   as a bug
-}
dropPrefix : String
dropPrefix =
    "DROP: bad id (expecting "


{-| Cheesy check to see if a JSON decode error was likely due to a
correct decoder that found an `id` sequence number mismatch.
-}
errorIsWarning : String -> Bool
errorIsWarning =
    String.startsWith ("I ran into a `fail` decoder: " ++ dropPrefix)
