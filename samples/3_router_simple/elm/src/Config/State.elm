module Config.State exposing (..)

{-|
   State handling for the CLI config feature
-}

import EnTrance.Endpoint as Endpoint exposing (RpcData(..))
import Utils.Extra.Response as Response exposing (pure)
import Utils.Samples as Samples
import Config.Munge as Munge
import Config.Remote exposing (..)
import Config.Types exposing (..)


{- Initial model -}


initialModel : String -> Model
initialModel websocket =
    { config = ""
    , checkOnly = False
    , rawView = False
    , commitResult = NotAsked
    , failuresResult = NotAsked
    , mungedFailures = Munge.empty
    , samples = Samples.initialState "new-config-sample"
    , connectionUp = False
    , endpoint = Endpoint.named endpoint websocket
    }



{- When we are connected to the server, load up the sample configuration snippets -}


websocketUp : Model -> ( Model, Cmd Msg )
websocketUp model =
    sendReq PersistLoadReq model
        |> Response.andThen (sendReq StartFeatureReq)



{- The samples dropdown needs a subscription to close if you click away -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Samples.subscriptions model.samples
        |> Sub.map SamplesMsg



{-
   Update
-}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CommitMsg checkOnly ->
            sendReq (ConfigLoadReq model.config)
                { model
                    | commitResult = Endpoint.loading model
                    , failuresResult = NotAsked
                    , mungedFailures = Munge.empty
                    , checkOnly = checkOnly
                }

        UpdateConfigMsg config ->
            pure { model | config = config }

        LoadMsg name ->
            pure
                { model
                    | config = Maybe.withDefault "" (Samples.get name model.samples)
                    , samples = Samples.saveName name model.samples
                }

        SamplesMsg sMsg ->
            Samples.update sMsg model model.config sendReq PersistSaveReq

        RawViewMsg rawView ->
            pure { model | rawView = rawView }



{-
   Incoming notifications from server
-}


nfnUpdate : Notification -> Model -> ( Model, Cmd Msg )
nfnUpdate nfn model =
    case nfn of
        ConfigLoadNfn result ->
            case result of
                Success _ ->
                    {- The config load operation worked, so go ahead and do
                       the commit/validate operation the user actually wanted
                    -}
                    sendReq (ConfigCommitReq model.checkOnly)
                        { model | commitResult = Endpoint.loading model }

                _ ->
                    {- Config load didn't work - probably syntactic errors -}
                    pure { model | commitResult = result }

        ConfigCommitNfn result ->
            case result of
                Success _ ->
                    {- Commit/validate worked -}
                    pure { model | commitResult = result }

                _ ->
                    {- Commit/validate failed - fetch the errors (slow) -}
                    sendReq ConfigGetFailuresReq
                        { model
                            | commitResult = Failure "Rendering errors in CLI format..."
                            , failuresResult = Endpoint.loading model
                        }

        ConfigGetFailuresNfn result ->
            {- Retrieved the failures in CLI format -}
            pure
                { model
                    | failuresResult = result
                    , mungedFailures = Munge.fromResult result
                }

        PersistLoadNfn saves ->
            pure { model | samples = Samples.load saves model.samples }

        ConStateNfn connectionUp ->
            pure { model | connectionUp = connectionUp }



{-
   "Clear" button clicked
-}


clearAll : Model -> Model
clearAll model =
    { model
        | commitResult = NotAsked
        , failuresResult = NotAsked
        , mungedFailures = Munge.empty
    }
