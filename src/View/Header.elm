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
        [ documentControls model
        , sharingControls model
        , E.el [ E.alignLeft ] Button.toggleCheatSheet
        , E.el [ E.alignRight ] (Button.toggleTagsSidebar model.sidebarTagsState)
        , View.Utility.hideIf (model.currentUser == Nothing) Button.toggleChat
        ]


documentControls model =
    E.row [ E.spacing 6 ]
        [ View.Utility.hideIf (model.currentUser == Nothing) (Button.languageMenu model.popupState model.language)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.showIf model.showEditor Button.closeEditor)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.hideIf model.showEditor Button.openEditor)
        , View.Utility.hideIf (model.currentUser == Nothing) (Button.popupNewDocumentForm model.popupState)
        , showIfUserIsDocumentAuthor model (model.currentUser /= Nothing) (Button.deleteDocument model)
        , showIfUserIsDocumentAuthor model (model.currentUser /= Nothing) (Button.cancelDeleteDocument model)
        , View.Utility.showIf model.showEditor (Button.togglePublic model.currentDocument)
        , View.Utility.showIf model.showEditor (E.el [ E.alignRight ] (wordCount model))
        , View.Utility.currentDocumentAuthor (Maybe.map .username model.currentUser) model.currentDocument
        ]


sharingControls model =
    E.row [ E.spacing 6, E.paddingXY 18 0 ]
        [ showIfUserIsDocumentAuthor model (model.currentUser /= Nothing) Button.share
        , showIfDocumentIsShared model (model.currentUser /= Nothing) (Button.toggleLock model.currentDocument)
        , View.Utility.currentDocumentEditor (Maybe.map .username model.currentUser) model.currentDocument
        , showIfDocumentIsShared model (model.currentUser /= Nothing) (Button.sendUnlockMessage model)
        ]


showIfUserIsDocumentAuthor model condition element =
    View.Utility.showIf
        ((model.currentUser /= Nothing) && (Maybe.andThen .author model.currentDocument == Maybe.map .username model.currentUser && condition))
        element


showIfDocumentIsShared model condition element =
    View.Utility.showIf
        ((model.currentUser /= Nothing)
            && (Maybe.map (View.Utility.isShared_ (Maybe.map .username model.currentUser)) model.currentDocument
                    == Just True
                    && condition
               )
        )
        element


wordCount : FrontendModel -> Element FrontendMsg
wordCount model =
    case model.currentDocument of
        Nothing ->
            E.none

        Just doc ->
            E.el [ Font.size 14, Font.color Color.lightGray ] (E.text <| "words: " ++ (String.fromInt <| Document.wordCount doc))



-- viewRendered
