module Config.Munge exposing (..)

{-| Munge the text errors/warnings into a data structure suitable for a
more structured view
-}

import Regex
import EnTrance.Endpoint exposing (RpcData(..))


type alias Errors =
    List ( String, String )


empty : Errors
empty =
    []


isEmpty : Errors -> Bool
isEmpty =
    List.isEmpty


fromResult : RpcData String -> Errors
fromResult result =
    case result of
        Failure errs ->
            String.split "\n" errs
                |> List.drop 6
                |> zipify

        _ ->
            empty


zipify : List String -> Errors
zipify lines =
    List.map2 (,) ("" :: lines) lines
        |> List.filterMap filter


filter : ( String, String ) -> Maybe ( String, String )
filter ( thisLine, nextLine ) =
    let
        matches =
            Regex.find (Regex.AtMost 1) prefix nextLine
    in
        if List.isEmpty matches then
            if String.startsWith "!!% " thisLine then
                Nothing
            else
                Just ( thisLine, "" )
        else
            List.head matches
                |> Maybe.andThen (\m -> List.head m.submatches)
                |> Maybe.andThen identity
                |> Maybe.andThen (\m -> Just ( thisLine, m ))


prefix : Regex.Regex
prefix =
    Regex.regex "^!!% (?:ERROR: |UNSUPPORTED: )?(.*)"
