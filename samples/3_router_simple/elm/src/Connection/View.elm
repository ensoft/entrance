module Connection.View exposing (view)

{-|
   View for the connection management dialog
-}

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Bootstrap.Alert as Alert
import Bootstrap.Modal as Modal
import Bootstrap.Tab as Tab
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Radio as Radio
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Button as Button
import Bootstrap.Table as Table
import Connection.Types exposing (..)


{-
   Overall view: assemble the three tabs (credentials, state, and history)
-}


view : Model -> Html Msg
view model =
    Modal.config CancelMsg
        |> Modal.large
        |> Modal.withAnimation AnimateModalMsg
        |> Modal.h3 [] [ text "Connection" ]
        |> Modal.body [ id "connection-modal-contents" ]
            [ Tab.config TabMsg
                |> Tab.withAnimation
                |> Tab.items
                    [ tab "Credentials" <| credentials model
                    , tab "Status" <| status model
                    , tab "History" <| history model
                    ]
                |> Tab.view model.tabState
            ]
        |> Modal.footer [] (footer model)
        |> Modal.view model.modalVisibility


tab : String -> Html msg -> Tab.Item msg
tab name contents =
    Tab.item
        { id = "Connection" ++ name ++ "Tab"
        , link = Tab.link [] [ text name ]
        , pane = Tab.pane [ class "big-top-spacer" ] [ contents ]
        }



{-
   The buttons along the bottom of the dialog change depending on the state
-}


footer : Model -> List (Html Msg)
footer model =
    let
        ( maybeSave, connectLabel ) =
            if model.newConnParams /= model.connection.params then
                ( Button.button
                    [ Button.outlineSuccess
                    , Button.disabled <| invalidPort model Either
                    , Button.attrs [ onClick SaveMsg ]
                    ]
                    [ text "Save Credentials" ]
                , "Save and Connect"
                )
            else
                ( text "", "Connect" )
    in
        [ let
            ( cls, txt, _ ) =
                viewConnState model.connection.overallState
          in
            span [ class (cls ++ " mr-auto") ] [ text ("◯ " ++ txt) ]
        , maybeSave
        , if connectable model.connection.overallState then
            Button.button
                [ Button.outlineSuccess
                , Button.disabled <| invalidPort model Either
                , Button.attrs [ onClick ConnectAndSaveMsg ]
                ]
                [ text connectLabel ]
          else
            text ""
        , if disconnectable model.connection.overallState then
            Button.button
                [ Button.outlineDanger
                , Button.attrs [ onClick DisconnectMsg ]
                ]
                [ text "Disconnect" ]
          else
            text ""
        , Button.button
            [ Button.outlineSecondary
            , Button.attrs [ onClick (AnimateModalMsg Modal.hiddenAnimated) ]
            ]
            [ text "Close" ]
        ]



{- Does the overall connection state warrant showing a "Connect" button? -}


connectable : ConnState -> Bool
connectable connState =
    case connState of
        Disconnected ->
            True

        FailureWhileDisconnecting _ ->
            True

        Disconnecting ->
            True

        FailedToConnect _ ->
            True

        _ ->
            False



{- Does the overall connection state warrant showing a "Disconnect" button? -}


disconnectable : ConnState -> Bool
disconnectable connState =
    case connState of
        Disconnected ->
            False

        _ ->
            True


viewConnState : ConnState -> ( String, String, List (Html msg) -> Html msg )
viewConnState status =
    case status of
        Disconnected ->
            ( "state-grey", "Disconnected", Alert.simpleInfo [] )

        Connected ->
            ( "state-green", "Connected", Alert.simpleSuccess [] )

        FailureWhileDisconnecting err ->
            ( "state-red", "Failure while disconnecting: " ++ err, Alert.simpleDanger [] )

        Finalizing ->
            ( "state-amber", "Finalizing connection", Alert.simpleWarning [] )

        Connecting ->
            ( "state-amber", "Connecting", Alert.simpleWarning [] )

        Disconnecting ->
            ( "state-amber", "Disconnecting", Alert.simpleWarning [] )

        ReconnectingAfterFailure err ->
            ( "state-red", "Reconnecting after faliure: " ++ err, Alert.simpleDanger [] )

        FailedToConnect err ->
            ( "state-red", "Failed to connect: " ++ err, Alert.simpleDanger [] )



{- Don't let us save/connect with credentials with an obviously bogus port -}


type Port
    = Ssh
    | Netconf
    | Either


invalidPort : Model -> Port -> Bool
invalidPort model portType =
    let
        invalid portString =
            (Result.withDefault 0 (String.toInt portString) <= 0)
                || (Result.withDefault 65536 (String.toInt portString) >= 65536)
    in
        case portType of
            Ssh ->
                invalid model.newConnParams.sshPort

            Netconf ->
                invalid model.newConnParams.netconfPort

            Either ->
                invalid model.newConnParams.sshPort || invalid model.newConnParams.netconfPort



{-
   UI to enter credentials
-}


credentials : Model -> Html Msg
credentials model =
    Grid.containerFluid []
        [ Form.form []
            [ Form.row []
                [ Form.colLabel [ Col.md2 ] [ text "Router:" ]
                , Form.col [ Col.md4 ]
                    [ Input.text
                        [ Input.attrs
                            [ value model.newConnParams.host
                            , onInput (ConnParamsMsg << Host)
                            ]
                        ]
                    ]
                , Form.colLabel [ Col.md3 ] [ text "SSH port:" ]
                , Form.col [ Col.md3 ]
                    [ Input.text
                        [ Input.attrs
                            [ value model.newConnParams.sshPort
                            , onInput (ConnParamsMsg << SshPort)
                            , classList [ ( "bad-input", invalidPort model Ssh ) ]
                            ]
                        ]
                    ]
                ]
            , Form.row []
                [ Form.colLabel
                    [ Col.md2 ]
                    [ text "Username:" ]
                , Form.col [ Col.md4 ]
                    [ Input.text
                        [ Input.attrs
                            [ value model.newConnParams.username
                            , onInput (ConnParamsMsg << Username)
                            ]
                        ]
                    ]
                , Form.colLabel [ Col.md3 ] [ text "Netconf port:" ]
                , Form.col [ Col.md3 ]
                    [ Input.text
                        [ Input.attrs
                            [ value model.newConnParams.netconfPort
                            , onInput (ConnParamsMsg << NetconfPort)
                            , classList [ ( "bad-input", invalidPort model Netconf ) ]
                            ]
                        ]
                    ]
                ]
            , Form.row []
                [ Form.colLabel [ Col.md2 ] [ text "Secret:" ]
                , Form.col [ Col.md4 ]
                    [ (if model.newConnParams.authType == Password then
                        Input.password
                       else
                        Input.text
                      )
                        [ Input.attrs
                            [ value model.newConnParams.secret
                            , onInput (ConnParamsMsg << Secret)
                            ]
                        ]
                    ]
                , Form.colLabel [ Col.md1 ] [ text "" ]
                , Form.col [ Col.md5 ]
                    [ Checkbox.checkbox
                        [ Checkbox.checked model.newConnParams.autoConnect
                        , Checkbox.onCheck (ConnParamsMsg << AutoConnect)
                        ]
                        "Connect automatically on startup"
                    ]
                ]
            , Form.row []
                [ Form.colLabel [ Col.md2 ] [ text "Secret type:" ]
                , Form.col [ Col.md5 ]
                    (let
                        isPassword =
                            case model.newConnParams.authType of
                                Password ->
                                    True

                                SshKey ->
                                    False
                     in
                        Radio.radioList "authType"
                            [ Radio.create
                                [ Radio.inline
                                , Radio.checked isPassword
                                , Radio.onClick <| ConnParamsMsg (AuthType Password)
                                ]
                                "Password"
                            , Radio.create
                                [ Radio.inline
                                , Radio.checked (not isPassword)
                                , Radio.onClick <| ConnParamsMsg (AuthType SshKey)
                                ]
                                "SSH key"
                            ]
                    )
                , Form.colLabel [ Col.md2 ] [ text "" ]
                ]
            ]
        ]



{-
   "State" summary tab
-}


status : Model -> Html Msg
status model =
    let
        viewOne connection state =
            let
                ( _, txt, alert ) =
                    viewConnState state
            in
                alert [ text <| connection ++ ": " ++ txt ]

        viewDictItem connection state rest =
            viewOne connection state :: rest
    in
        (viewOne "Overall" model.connection.overallState)
            :: Dict.foldr viewDictItem [] model.connection.childStates
            |> div []



{-
   Connection state history tab
-}


history : Model -> Html Msg
history model =
    let
        viewItem ( time, connection, state, globalState ) =
            let
                ( cls, txt, _ ) =
                    viewConnState state

                ( _, global, _ ) =
                    viewConnState globalState
            in
                Table.tr [ Table.rowAttr (class cls) ]
                    [ Table.td [] [ text time ]
                    , Table.td [] [ text connection ]
                    , Table.td [] [ text txt ]
                    , Table.td [] [ text global ]
                    ]
    in
        Table.simpleTable
            ( Table.simpleThead
                [ Table.th [] [ text "Time" ]
                , Table.th [] [ text "Connection" ]
                , Table.th [] [ text "State" ]
                , Table.th [] [ text "Overall state" ]
                ]
            , Table.tbody [] (List.map viewItem model.connection.stateHistory)
            )
