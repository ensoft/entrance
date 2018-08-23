module TopLevel.Remote exposing (..)

{-| Top-level Remote handling: just configuring how the endpoints stitch together
-}

import Dict
import EnTrance.Notification as Notification exposing (delegateTo)
import TopLevel.Types exposing (..)
import Config.Remote as Config
import Connection.Remote as Connection
import Exec.Remote as Exec
import Logs.Remote as Logs
import Netconf.Remote as Netconf


cfg : Notification.Config Model Notification
cfg =
    Notification.Config
        GlobalNfn
        (Dict.fromList
            [ ( Config.endpoint
              , delegateTo Config.nfnDecoder .config ConfigNfn
              )
            , ( Connection.endpoint
              , delegateTo Connection.nfnDecoder .connection ConnectionNfn
              )
            , ( Exec.endpoint
              , delegateTo Exec.nfnDecoder .exec ExecNfn
              )
            , ( Logs.endpoint
              , delegateTo Logs.nfnDecoder .logs LogsNfn
              )
            , ( Netconf.endpoint
              , delegateTo Netconf.nfnDecoder .netconf NetconfNfn
              )
            ]
        )
