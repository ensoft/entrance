module Netconf.State exposing (..)

{-|
   Netconf state handling
-}

import EnTrance.Endpoint as Endpoint exposing (RpcData(..))
import Utils.Extra.Response as Response exposing (pure)
import Utils.Samples as Samples
import Netconf.Types exposing (..)
import Netconf.Remote exposing (..)


{-
   Initial state
-}


initialModel : String -> Model
initialModel websocket =
    { xml = ""
    , -- dummy last netconf operation, doesn't matter
      lastOp = Commit
    , nextOp = NoneNext
    , samples = Samples.initialState "new-xml-sample"
    , result = NotAsked
    , connectionUp = False
    , endpoint = Endpoint.named endpoint websocket
    }



{-
   When our server connection is up, request any saved XML samples and start
   the netconf feature on the server
-}


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
        NetconfOpMsg op ->
            let
                ( opToIssue, nextOp ) =
                    case op of
                        Validate ->
                            ( EditConfig model.xml, ValidateNext )

                        Commit ->
                            ( EditConfig model.xml, CommitNext )

                        _ ->
                            ( op, NoneNext )
            in
                sendReq (NetconfReq opToIssue)
                    { model
                        | result = Endpoint.loading model
                        , nextOp = nextOp
                        , lastOp = opToIssue
                    }

        UpdateXMLMsg xml ->
            pure { model | xml = xml }

        LoadMsg name ->
            pure
                { model
                    | xml = Maybe.withDefault "" (Samples.get name model.samples)
                    , samples = Samples.saveName name model.samples
                }

        SamplesMsg sMsg ->
            Samples.update sMsg model model.xml sendReq PersistSaveReq



{-
   Handle inbound notifications from the server
-}


nfnUpdate : Notification -> Model -> ( Model, Cmd Msg )
nfnUpdate nfn model =
    case nfn of
        NetconfNfn result ->
            case ( result, model.nextOp ) of
                -- If we just did a successful edit-config, then automatically
                -- kick off a validate or commit if that's what was teed up
                ( Success _, ValidateNext ) ->
                    sendReq (NetconfReq Validate)
                        { model
                            | result = Endpoint.loading model
                            , lastOp = Validate
                            , nextOp = NoneNext
                        }

                ( Success _, CommitNext ) ->
                    sendReq (NetconfReq Commit)
                        { model
                            | result = Endpoint.loading model
                            , lastOp = Commit
                            , nextOp = NoneNext
                        }

                _ ->
                    { model | result = result } ! []

        PersistLoadNfn saves ->
            pure { model | samples = Samples.load saves model.samples }

        ConStateNfn connectionUp ->
            pure { model | connectionUp = connectionUp }



{- User clicked the "Clear" button -}


clearAll : Model -> Model
clearAll model =
    { model | result = NotAsked }
