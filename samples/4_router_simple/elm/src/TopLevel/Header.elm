module TopLevel.Header exposing (view)

{-| This module factors out the complex bit of the main view that isn't just
composing sub-elements. So the navbar, "about" modal dialog, restart
confirmation modal dialog, ping failure modal, and global error list.
-}

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Connection.Types as Connection
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, href, src)
import Html.Events exposing (onClick)
import TopLevel.Types exposing (Model, Msg(..))
import Utils.ViewHelper as ViewHelper


{-| Main view
-}
view : Model -> Html Msg
view model =
    div []
        [ aboutModal model.aboutModalVisibility
        , confirmRestartModal model.restartModalState
        , navbar model
        , div [] <| List.map (\x -> Alert.simpleDanger [] [ text x ]) model.errors
        ]


{-| Navbar
-}
navbar : Model -> Html Msg
navbar model =
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.dark
        |> Navbar.brand
            [ href "/" ]
            [ text "EnTrance router demo" ]
        |> Navbar.items
            [ Navbar.dropdown
                { id = "header-dropdown"
                , toggle = Navbar.dropdownToggle [] [ text "Options" ]
                , items =
                    [ Navbar.dropdownHeader [ text "Show" ]
                    , Navbar.dropdownItem
                        [ onClick <| AnimateAboutModalMsg Modal.shown ]
                        [ text "About…" ]
                    , -- We slightly naughtily know which connection message
                      -- will cause the connection dialog to pop up
                      Navbar.dropdownItem
                        [ onClick <| ConnectionMsg Connection.ShowConnection ]
                        [ text "Connection…" ]
                    , Navbar.dropdownDivider
                    , Navbar.dropdownHeader [ text "Internal" ]
                    , Navbar.dropdownItem
                        [ onClick ConfirmRestartMsg ]
                        [ text "Restart…" ]
                    ]
                }
            , Navbar.itemLink
                [ onClick ClearAllMsg ]
                [ text "Clear" ]
            ]
        |> Navbar.customItems
            [ Html.img
                [ src "router.png"
                , class "fit-in-navbar hidden-sm-down"
                ]
                []
                |> Navbar.customItem
            ]
        |> Navbar.view model.navbarState


{-| "About" modal
-}
aboutModal : Modal.Visibility -> Html Msg
aboutModal visible =
    Modal.config (AnimateAboutModalMsg Modal.hidden)
        |> Modal.large
        |> Modal.withAnimation AnimateAboutModalMsg
        |> Modal.h3 [] [ text "About this app" ]
        |> Modal.body []
            [ img
                [ src "about.png"
                , class "img-fluid"
                ]
                []
            ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs [ onClick (AnimateAboutModalMsg Modal.hiddenAnimated) ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view visible


{-| Confirm restart modal
-}
confirmRestartModal : Modal.Visibility -> Html Msg
confirmRestartModal state =
    ViewHelper.confirmModal
        "Confirm restart"
        "Do you really want to restart? This will impact all current client sessions."
        "Restart"
        "Cancel"
        state
        RestartServerMsg
        AbortRestartMsg
