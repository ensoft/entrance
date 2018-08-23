module Utils.Extra.Response exposing (..)

{-| Extra functions for Response types. Will be in next version of Response package.
-}

import Response exposing (Response, res, withNone)


{-| Construct a result from model and multiple cmds, flipped for piping:
    { model | foo = bar }
      |> withCmds [someCmd1, someCmd1]
-}
withCmds : List (Cmd a) -> m -> Response m a
withCmds cmds model =
    res model (Cmd.batch cmds)


{-| Sequence one update after another.
    update1 : Model -> Response Model (Cmd Msg)
    update2 : Model -> Response Model (Cmd Msg)
    update3 : Model -> Response Model (Cmd Msg)
    update1 model
    |> andThen update2
    |> andThen update3
-}
andThen : (m -> Response m a) -> Response m a -> Response m a
andThen update ( model1, cmd1 ) =
    -- For those into abstractions: this can be viewed as considering
    -- Response as a Writer monad, with the effect of monoidally
    -- aggregating commands along the way.
    let
        ( model2, cmd2 ) =
            update model1
    in
        res model2 (Cmd.batch [ cmd1, cmd2 ])


{-| Synonym for withNone (for those with a personal preference).
    pure { model | foo = bar }
-}
pure : m -> Response m a
pure =
    -- For those into abstractions: same as for andThen.
    withNone
