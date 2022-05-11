module View.Header exposing (view)

import Document
import Element as E exposing (Element)
import Element.Font as Font
import Predicate
import Types exposing (FrontendModel, FrontendMsg)
import View.Button as Button
import View.Color as Color
import View.Utility


view model _ =
    E.row [ E.spacing 12, E.width E.fill ]
        [ documentControls model
        , sharingControls model
        , E.row [ E.centerX, E.spacing 8 ] [ Button.toggleManuals, Button.toggleCheatSheet ]
        , E.el [ E.alignRight ] (Button.toggleTagsSidebar model.sidebarTagsState)
        , View.Utility.hideIf (model.currentUser == Nothing) Button.toggleChat
        ]


documentControls model =
    E.row [ E.spacing 6 ]
        [ View.Utility.hideIf (model.currentUser == Nothing) (Button.languageMenu model.popupState model.language)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.showIf model.showEditor Button.closeEditor)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.hideIf model.showEditor Button.openEditor)

        --, Button.startCollaborativeEditing model
        , View.Utility.hideIf (model.currentUser == Nothing) (Button.popupNewDocumentForm model.popupState)
        , showIfUserIsDocumentAuthor model (model.currentUser /= Nothing) (Button.softDeleteDocument model)
        , showIfUserIsDocumentAuthor model (model.currentUser /= Nothing) (Button.hardDeleteDocument model)
        , showIfUserIsDocumentAuthor model (model.currentUser /= Nothing) (Button.cancelDeleteDocument model)
        , View.Utility.showIf model.showEditor (Button.togglePublic model.currentDocument)
        , View.Utility.currentDocumentAuthor (Maybe.map .username model.currentUser) model.currentDocument
        ]


sharingControls model =
    E.row [ E.spacing 6, E.paddingXY 18 0 ]
        [ showIfUserIsDocumentAuthor model (model.currentUser /= Nothing) Button.share

        --, View.Utility.currentDocumentEditor (Maybe.map .username model.currentUser) model.currentDocument
        --, showIfDocumentIsShared model (model.currentUser /= Nothing) (Button.sendUnlockMessage model)
        ]


showIfUserIsDocumentAuthor model condition element =
    View.Utility.showIf
        ((model.currentUser /= Nothing) && (Maybe.andThen .author model.currentDocument == Maybe.map .username model.currentUser && condition))
        element


showIfDocumentIsShared model condition element =
    View.Utility.showIf
        ((model.currentUser /= Nothing)
            && (Maybe.map (Predicate.isShared_ (Maybe.map .username model.currentUser)) model.currentDocument
                    == Just True
                    && condition
               )
        )
        element



-- viewRendered
