module Utils.LoL exposing
    ( LoL
    , empty
    , add
    , map
    , isEmpty
    )

{-| List-of-Lists module.


# Definition

@docs LoL


# Common Helpers

@docs empty
@docs add
@docs map
@docs isEmpty

-}


{-| Timed list-of-list: determine whether to start a new list based on whether
the item is added within a certain number of seconds as the previous addition
-}
type alias LoL a =
    { cur : List a
    , old : List (List a)
    , lastTime : Float
    , window : Float
    }


{-| Empty timed-list-of-lists value
-}
empty : Float -> LoL a
empty window =
    { cur = [], old = [], lastTime = -window, window = window }


{-| Add an item to a list-of-lists, optionally starting a new list
-}
add : a -> Float -> LoL a -> LoL a
add item time lol =
    if time - lol.lastTime > lol.window then
        { lol
            | cur = [ item ]
            , old = lol.cur :: lol.old
            , lastTime = time
        }

    else
        { lol
            | cur = item :: lol.cur
            , lastTime = time
        }


{-| Map over the entire list
-}
map : (List a -> b) -> LoL a -> List b
map fn lol =
    List.map fn (lol.cur :: lol.old)


{-| Is the list-of-lists empty
-}
isEmpty : LoL a -> Bool
isEmpty lol =
    List.isEmpty lol.cur && List.isEmpty lol.old
