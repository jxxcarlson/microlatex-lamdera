module View.SignUp exposing (view)

import Config
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Types exposing (ActiveDocList(..), AppMode(..), DocPermissions(..), FrontendModel, FrontendMsg(..), MaximizedIndex(..), SidebarState(..), SignupState(..), SortMode(..))
import View.Button as Button
import View.Color as Color
import View.Input
import View.Style
import View.Utility


view model =
    case model.signupState of
        HideSignUpForm ->
            E.none

        ShowSignUpForm ->
            E.column [ E.moveRight 400, E.spacing 12, E.width (E.px 400), E.height (E.px 600), E.padding 30, Background.color Color.paleViolet ]
                [ E.row [] [ label "Username", View.Input.usernameLarge model ]
                , E.row [] [ label "Real name", View.Input.realName model ]
                , E.row [] [ label "Email", View.Input.email model ]
                , E.row [] [ label "Password", View.Input.passwordLarge model ]
                , E.row [] [ label "Password again", View.Input.passwordAgain model ]
                , E.row [ E.spacing 12 ] [ Button.doSignUp, Button.cancelSignUp ]
                , E.paragraph [ Font.size 14, Font.color Color.darkRed ] [ E.text model.message ]
                , E.paragraph [ Font.size 14, E.paddingEach { left = 0, right = 0, top = 40, bottom = 0 } ]
                    [ E.text "Your user name, real name and email will not be shared."
                    ]
                ]


label str =
    E.el [ Font.size 14, E.width (E.px 120) ] (E.text str)
