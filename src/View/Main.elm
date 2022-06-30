module View.Main exposing (view)

import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Html exposing (Html)
import Parser.Language exposing (Language(..))
import Types exposing (AppMode(..), FrontendModel, FrontendMsg, PopupState(..))
import View.Admin as Admin
import View.Button as Button
import View.CheatSheet as Manual
import View.Color as Color
import View.Editor as Editor
import View.Footer as Footer
import View.Geometry as Geometry
import View.Header as Header
import View.Index as Index
import View.Input
import View.Popups.Signin
import View.Rendered as Rendered
import View.Share as Share
import View.Sidebar as Sidebar
import View.SignUp as SignUp
import View.Style as Style
import View.TopHeader as TopHeader
import View.Utility


type alias Model =
    FrontendModel


view : Model -> Html FrontendMsg
view model =
    E.layoutWith { options = [ E.focusStyle View.Utility.noFocus ] }
        [ Style.bgGray 0.9, E.clipX, E.clipY ]
        (viewMainColumn model)


viewMainColumn : Model -> Element FrontendMsg
viewMainColumn model =
    case model.appMode of
        AdminMode ->
            Admin.view model

        UserMode ->
            if model.showEditor then
                viewEditorAndRenderedText model

            else
                viewRenderedTextOnly model


viewRenderedTextOnly : Model -> Element FrontendMsg
viewRenderedTextOnly model =
    let
        deltaH =
            (Geometry.appHeight model - 100) // 2 + 135
    in
    E.column (Style.mainColumn model)
        [ E.column
            [ E.inFront (languageMenu model)
            , E.inFront (E.el [ E.moveDown 70, E.moveRight 10 ] (newDocumentPopup model))
            , E.inFront (E.el [ E.moveDown 70, E.moveRight 10 ] (Share.view model))
            , E.inFront (E.el [ E.moveDown 90, E.moveRight 270 ] (Share.usermessage model.userMessage))
            , E.inFront (E.el [ E.moveDown 93, E.moveRight 680 ] (Manual.view model))
            , E.inFront (View.Popups.Signin.view model)
            , E.centerX
            , E.width (E.px <| Geometry.smallAppWidth model.windowWidth)

            --, E.width (E.px <| Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth)
            , E.height (E.px (Geometry.appHeight model))
            ]
            [ headerRow model
            , E.row [ E.spacing 18, E.inFront (SignUp.view model) ]
                [ viewRenderedContainer model
                , Index.view model (Geometry.smallAppWidth model.windowWidth) deltaH
                , E.el [ E.moveLeft 90 ] (Sidebar.viewTags model)
                , Sidebar.viewExtras model
                ]
            , Footer.view model (Geometry.smallHeaderWidth model.windowWidth)
            ]
        ]


viewEditorAndRenderedText : Model -> Element FrontendMsg
viewEditorAndRenderedText model =
    let
        deltaH =
            (Geometry.appHeight model - 100) // 2 + 135
    in
    E.column (Style.mainColumn model)
        [ E.column
            [ E.inFront (languageMenu model)
            , E.inFront (E.el [ E.moveDown 70, E.moveRight 10 ] (newDocumentPopup model))
            , E.inFront (E.el [ E.moveDown 70, E.moveRight 365 ] (Share.view model))
            , E.inFront (E.el [ E.moveDown 90, E.moveRight 170 ] (Share.usermessage model.userMessage))
            , E.inFront (E.el [ E.moveDown 93, dyCheatSheet model.showEditor ] (Manual.view model))
            , E.width (E.px <| Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth)
            , E.height (E.px (Geometry.appHeight model))
            ]
            [ headerRow model
            , E.row [ E.spacing 12 ]
                [ Editor.view model
                , Rendered.viewForEditor model (Geometry.panelWidth_ model.showTOC model.sidebarExtrasState model.sidebarTagsState model.windowWidth)
                , View.Utility.showIf model.showTOC (Index.view model (Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth) (deltaH + 10))
                , Sidebar.viewExtras model
                , Sidebar.viewTags model
                , View.Utility.showIf (model.showEditor && not model.showTOC) <| E.el [ E.alignTop, E.paddingXY 0 30 ] (Button.toggleTOC model.showTOC)
                ]
            , Footer.view model (Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState (model.windowWidth - 80))
            ]
        ]


dyCheatSheet : Bool -> E.Attr decorative msg
dyCheatSheet showEditor =
    if showEditor then
        E.moveRight 920

    else
        E.moveRight 1000


languageMenu : FrontendModel -> Element FrontendMsg
languageMenu model =
    case model.popupState of
        LanguageMenuPopup ->
            E.column [ E.moveDown 35, E.spacing 12, E.padding 20, Background.color (Color.gray 0.35), E.width (E.px 200), E.height (E.px 300) ]
                [ Button.setLanguage True model.language L0Lang "L0"
                , Button.setLanguage True model.language MicroLaTeXLang "MicroLaTeX"
                , Button.setLanguage True model.language PlainTextLang "Plain text"
                , Button.setLanguage True model.language XMarkdownLang "XMarkdown"
                ]

        _ ->
            E.none


newDocumentPopup : FrontendModel -> Element FrontendMsg
newDocumentPopup model =
    case model.popupState of
        NewDocumentPopup ->
            let
                message =
                    if String.length model.inputTitle < 4 then
                        "Title must contain at least three letters"

                    else
                        ""
            in
            E.column [ Font.size 14, E.moveDown 35, E.spacing 36, E.padding 20, Background.color (Color.gray 0.35), E.width (E.px 600), E.height (E.px 250) ]
                [ E.row [ E.spacing 12 ] [ View.Input.title model, Button.dismissPopup ]
                , E.el [ Font.color Color.white ] (E.text message)
                , E.row [ E.spacing 12 ]
                    [ E.el [ Font.color Color.white ] (E.text "Language")
                    , Button.setLanguage False model.language L0Lang "L0"
                    , Button.setLanguage False model.language MicroLaTeXLang "MicroLaTeX"
                    , Button.setLanguage False model.language PlainTextLang "Plain text"
                    , Button.setLanguage False model.language XMarkdownLang "XMarkdown"
                    ]
                , Button.createDocument model.inputTitle
                ]

        _ ->
            E.none


headerRow model =
    E.column [ E.spacing 8, Background.color Color.darkGray, E.padding 12, E.width E.fill ]
        [ TopHeader.view model (E.px <| Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth)
        , Header.view model (E.px <| Geometry.smallHeaderWidth model.windowWidth)
        ]



-- HELPERS


viewRenderedContainer model =
    E.column [ E.spacing 18 ]
        [ Rendered.view model (Geometry.smallPanelWidth model.windowWidth)
        ]
