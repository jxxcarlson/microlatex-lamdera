module View.TopHeader exposing (view)

import Config
import Element as E exposing (Element)
import Types exposing (FrontendModel, FrontendMsg)
import View.Button as Button
import View.Input
import View.Style
import View.Utility


view : FrontendModel -> b -> Element FrontendMsg
view model _ =
    E.row [ E.spacing 12, E.width E.fill ]
        [ E.el [ E.alignRight ] (title Config.appName)
        , Button.iLink Types.StandardHandling Config.welcomeDocId "Home"
        , View.Input.searchDocsInput model
        , View.Utility.showIf (model.currentUser == Nothing) Button.signUp
        , View.Utility.showIf (model.currentUser == Nothing) Button.signIn
        , View.Utility.showIf (model.currentUser == Nothing) (View.Input.username model)
        , View.Utility.showIf (model.currentUser == Nothing) (View.Input.password model)
        , Button.signOut model
        , E.el [ E.alignRight, rightPaddingHeader model.showEditor ] (Button.toggleSidebar model.sidebarState)
        ]


title : String -> Element msg
title str =
    E.row [ E.centerX, View.Style.fgGray 0.9 ] [ E.text str ]


rightPaddingHeader showEditor =
    case showEditor of
        True ->
            E.paddingEach { left = 0, right = 30, top = 0, bottom = 0 }

        False ->
            E.paddingEach { left = 0, right = 0, top = 0, bottom = 0 }
