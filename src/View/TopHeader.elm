module View.TopHeader exposing (view)

import Config
import Element as E exposing (Element)
import Element.Font as Font
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (autofocus, id, placeholder, style, type_, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Types exposing (FrontendModel, FrontendMsg)
import View.Button as Button
import View.Color as Color
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

        --, View.Utility.showIf (model.currentUser == Nothing) (View.Input.password model)
        , View.Utility.showIf (model.currentUser == Nothing) (passwordInput model |> E.html)
        , Button.signOut model
        , View.Utility.hideIf (model.currentUser == Nothing) (E.el [ E.alignRight, rightPaddingHeader model.showEditor ] (Button.toggleExtrasSidebar model.sidebarExtrasState))
        ]


passwordInput : FrontendModel -> Html FrontendMsg
passwordInput model =
    input
        ([ id "password-input"
         , type_ "text"
         , onInput Types.InputPassword
         , style "height" "27px"
         , View.Utility.onEnter Types.SignIn
         , placeholder "password"
         , value model.inputPassword
         , style "padding-left" "8px"
         , style "margin-left" "18px"
         , style "width" "100px"
         , if model.inputPassword /= "" then
            style "color" "#444"

           else
            style "color" "#444"
         , if model.inputPassword /= "" then
            style "background-color" "#444"

           else
            style "background-color" "#fff"
         ]
            ++ fontStyles
        )
        []


fontStyles : List (Html.Attribute msg)
fontStyles =
    [ style "font-family" "Helvetica", style "font-size" "14px", style "line-height" "1.5" ]


title : String -> Element msg
title str =
    E.row [ E.centerX, View.Style.fgGray 0.9 ] [ E.text str ]


rightPaddingHeader showEditor =
    case showEditor of
        True ->
            E.paddingEach { left = 0, right = 30, top = 0, bottom = 0 }

        False ->
            E.paddingEach { left = 0, right = 0, top = 0, bottom = 0 }
