module EnTrance.Feature.Target.Config exposing
    ( load
    , decodeLoad
    , commit
    , CommitType(..)
    , decodeCommit
    , getFailures
    , decodeGetFailures
    , getUnvalidated
    , decodeGetUnvalidated
    , start
    , stop
    , decodeIsUp
    , parseFailures
    , Failed
    )

{-| Validating and commiting configuration changes via the CLI.

It takes a sequence of round-trip RPCs to actually get some configuration
committed.


## Load configuration into the target buffer

@docs load
@docs decodeLoad


## Commit or validate the target buffer config

@docs commit
@docs CommitType
@docs decodeCommit


## Get failures from a failed commit

@docs getFailures
@docs decodeGetFailures


## Get the config that could not be validated

@docs getUnvalidated
@docs decodeGetUnvalidated


# Starting and stopping

@docs start
@docs stop
@docs decodeIsUp


# Parsing failures

The result of a [getFailures](#getFailures) request is just a blob of text (as
provided by the router). You can parse this into a more structured form using
the following function.

@docs parseFailures
@docs Failed

-}

import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (MaybeSubscribe, RpcData)
import Json.Decode as Decode exposing (Decoder)
import Parser exposing ((|.), (|=), Parser, chompWhile, getChompedString, oneOf, succeed, token)
import RemoteData exposing (RemoteData(..))


{-| Name of the feature
-}
cli_config : String
cli_config =
    "cli_config"


{-| Enter some CLI-expressed configuration into the router's target buffer.

    Config.load "router bgp 10 \n neighbor 1.2.3.4 \n remote-as 20"
        |> Channel.sendRpc { model | loadResult = Loading }

-}
load : String -> Request
load config =
    Request.new "cli_config_load"
        |> Request.addString "config" config


{-| Decode the reply from a `load` request. Takes a message constructor.
-}
decodeLoad : (RpcData String -> msg) -> Decoder msg
decodeLoad makeMsg =
    Gen.decodeRpc "cli_config_load" Decode.string
        |> Decode.map makeMsg


{-| Commit the configuration that was loaded via [load](#load).

    Config.commit Commit
        |> Channel.sendRpc { model | commitResult = Loading }

-}
commit : CommitType -> Request
commit commitType =
    let
        checkOnly =
            case commitType of
                OnlyCheck ->
                    True

                Commit ->
                    False
    in
    Request.new "cli_config_commit"
        |> Request.addBool "check_only" checkOnly


{-| Whether a [commit](#commit) should actually change the configuration, or
merely validate.
-}
type CommitType
    = OnlyCheck
    | Commit


{-| Decode the reply from a `commit` request. Takes a message constructor.
-}
decodeCommit : (RpcData String -> msg) -> Decoder msg
decodeCommit makeMsg =
    Gen.decodeRpc "cli_config_commit" Decode.string
        |> Decode.map makeMsg


{-| Retrieve any failures from a [commit](#commit) (whether actually committed
or merely validated).

    Config.getFailures
        |> Channel.sendRpc { model | getFailuresResult = Loading }

-}
getFailures : Request
getFailures =
    Request.new "cli_config_get_failures"


{-| Decode the reply from a `getFailures` request. Takes a message constructor.
-}
decodeGetFailures : (RpcData String -> msg) -> Decoder msg
decodeGetFailures makeMsg =
    Gen.decodeRpc "cli_config_get_failures" Decode.string
        |> Decode.map makeMsg


{-| Retrieve any configuration items which could not be validated.

    Config.getUnvalidated
        |> Channel.sendRpc { model | getUnvalidatedResult = Loading }

-}
getUnvalidated : Request
getUnvalidated =
    Request.new "cli_config_get_unsupported"


{-| Decode the reply from a `getUnvalidated` request. Takes a message constructor.
-}
decodeGetUnvalidated : (RpcData String -> msg) -> Decoder msg
decodeGetUnvalidated makeMsg =
    Gen.decodeRpc "cli_config_get_unsupported" Decode.string
        |> Decode.map makeMsg


{-| Start a config feature instance. This represents the option to configure
one router. This is an async request - use the connection state notifications
to track progress.
-}
start : MaybeSubscribe -> Request
start =
    Gen.start cli_config


{-| Stop a config feature instance. This is an async request.
-}
stop : Request
stop =
    Gen.stop cli_config


{-| Decode an up/down notification requested by passing
[SubscribeToConState](EnTrance-Types#MaybeSubscribe) to
[start](#start). Takes a message constructor.
-}
decodeIsUp : (Bool -> msg) -> Decoder msg
decodeIsUp makeMsg =
    Gen.decodeIsUp cli_config
        |> Decode.map makeMsg



----------------------------------------------------------------------
-- Parsing failures
----------------------------------------------------------------------


{-| A line of configuration that has failed, and the error string that
prevented the configuration commit from succeeding.
-}
type alias Failed =
    { config : String
    , error : String
    }


{-| Parse the result of a [getFailures](#getFailures) request. If there is
anything awkward about the inputs, just return the empty list.
-}
parseFailures : RpcData String -> List Failed
parseFailures result =
    case result of
        Failure errs ->
            String.split "\n" errs
                |> List.drop 6
                |> zipify

        _ ->
            []


{-| Process a list of lines as adjacent pairs of lines.
-}
zipify : List String -> List Failed
zipify lines =
    List.map2 Tuple.pair
        ("" :: lines)
        lines
        |> List.filterMap filter


{-| Pick out the lines where the subsequent line is an error message (about the
current line)
-}
filter : ( String, String ) -> Maybe Failed
filter ( thisLine, nextLine ) =
    case getFailed nextLine of
        Just err ->
            Just (Failed thisLine err)

        Nothing ->
            if String.startsWith "!!% " thisLine then
                Nothing

            else
                Just (Failed thisLine "")


{-| Extract the error message from this line, if there is one
-}
getFailed : String -> Maybe String
getFailed line =
    case Parser.run errorParser line of
        Ok errMsg ->
            Just errMsg

        Err _ ->
            Nothing


errorParser : Parser String
errorParser =
    succeed identity
        |. token "!!% "
        |. oneOf [ token "ERROR: ", token "UNSUPPORTED: ", succeed () ]
        |= restOfLine


restOfLine : Parser String
restOfLine =
    getChompedString (chompWhile (\_ -> True))
