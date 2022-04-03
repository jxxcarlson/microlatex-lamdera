module View.Header exposing (view)

import Document
import Element as E exposing (Element)
import Element.Font as Font
import Types exposing (FrontendModel, FrontendMsg)
import View.Button as Button
import View.Color as Color
import View.Utility


view : FrontendModel -> b -> Element FrontendMsg
view model _ =
    E.row [ E.spacing 12, E.width E.fill ]
        [ View.Utility.hideIf (model.currentUser == Nothing) (Button.languageMenu model.popupState model.language)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.showIf model.showEditor Button.closeEditor)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.hideIf model.showEditor Button.openEditor)
        , View.Utility.hideIf (model.currentUser == Nothing) (Button.popupNewDocumentForm model.popupState)
        , View.Utility.hideIf (model.currentUser == Nothing) (Button.deleteDocument model)
        , View.Utility.showIf
            (Maybe.andThen .author model.currentDocument == Maybe.map .username model.currentUser)
            (Button.cancelDeleteDocument model)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.showIf model.showEditor (Button.togglePublic model.currentDocument))
        , E.el [ E.alignRight ] (wordCount model)
        , E.el [ Font.size 14, Font.color (E.rgb 0.9 0.9 0.9), E.alignRight ] (E.text (Document.currentAuthorFancy model.currentDocument))
        ]


wordCount : FrontendModel -> Element FrontendMsg
wordCount model =
    case model.currentDocument of
        Nothing ->
            E.none

        Just doc ->
            E.el [ Font.size 14, Font.color Color.lightGray ] (E.text <| "words: " ++ (String.fromInt <| Document.wordCount doc))



-- viewRendered
