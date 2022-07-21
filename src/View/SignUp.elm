module View.SignUp exposing (view)

import Element as E
import Element.Background as Background
import Element.Font as Font
import Message
import Parser.Language exposing (Language(..))
import Types exposing (SignupState(..))
import View.Button as Button
import View.Color as Color
import View.Input


view model =
    case model.signupState of
        HideSignUpForm ->
            E.none

        ShowSignUpForm ->
            E.column [ E.moveRight 400, E.spacing 12, E.width (E.px 400), E.height (E.px 600), E.padding 30, Background.color Color.paleViolet ]
                [ E.row [] [ label "Username", View.Input.signupUsername model ]
                , E.row [] [ label "Real name*", View.Input.realName model ]
                , E.row [] [ label "Email*", View.Input.email model ]
                , E.row [] [ label "Password", View.Input.passwordLarge model ]
                , E.row [] [ label "Password again", View.Input.passwordAgain model ]
                , E.row []
                    [ E.el [ E.alignTop ] (label "Language")
                    , E.column [ E.spacing 8 ]
                        [ Button.setUserLanguage model.inputLanguage L0Lang "L0"
                        , Button.setUserLanguage model.inputLanguage MicroLaTeXLang "MicroLaTeX"
                        , Button.setUserLanguage model.inputLanguage XMarkdownLang "XMarkdown"
                        ]
                    ]
                , E.row [ E.spacing 12, E.paddingEach { top = 30, bottom = 0, left = 0, right = 0 } ] [ Button.doSignUp, Button.cancelSignUp ]
                , E.paragraph [ Font.size 14, Font.color Color.darkRed ] (List.map Message.handleMessage model.messages)
                , E.paragraph [ Font.size 14, E.paddingEach { left = 0, right = 0, top = 10, bottom = 0 } ]
                    [ E.text "* Your real name and email are only to communicate with you. They will not be shared and will not be made public on this site."
                    , E.text " Documents are published with author = username unless you choose to reveal your full name."
                    ]
                ]


label str =
    E.el [ Font.size 14, E.width (E.px 120) ] (E.text str)
