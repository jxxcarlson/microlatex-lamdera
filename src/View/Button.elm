module View.Button exposing
    ( applyEdits
    , buttonTemplate
    , cancelDeleteDocument
    , cancelSignUp
    , clearChatHistory
    , clearConnectionDict
    , clearPassword
    , closeCollectionsIndex
    , closeEditor
    , createChatGroup
    , createDocument
    , createFolder
    , dismissPopup
    , dismissPublicUrlBox
    , dismissUserMessage
    , doShare
    , doSignUp
    , editDocument
    , experimentalMode
    , export
    , exportToLaTeX
    , exportToLaTeXRaw
    , exportToMarkown
    , getDocument
    , getDocumentByPrivateId
    , getPinnedDocs
    , getPublicTags
    , getUserList
    , getUserTags
    , hardDeleteDocument
    , help
    , home
    , iLink
    , languageMenu
    , linkTemplate
    , makeBackup
    , makeCurrentGroupPreferred
    , maximizeMyDocs
    , maximizePublicDocs
    , newFolder
    , nextSyncButton
    , openEditor
    , pinnedDocs
    , popupMonitor
    , popupNewDocumentForm
    , printToPDF
    , reply
    , runNetworkModelCommand
    , runSpecial
    , sendUnlockMessage
    , setChatCreate
    , setChatDisplay
    , setDocAsCurrentWithDocInfo
    , setDocumentAsCurrent
    , setDocumentInPhoneAsCurrent
    , setLanguage
    , setSortModeAlpha
    , setSortModeMostRecent
    , setUserLanguage
    , share
    , sharedDocs
    , showTOCInPhone
    , signIn
    , signOut
    , signUp
    , softDeleteDocument
    , standardDocs
    , startCollaborativeEditing
    , startupHelp
    , syncButton
    , syncLR
    , toggleActiveDocList
    , toggleAllowOpenFolder
    , toggleAppMode
    , toggleBackupVisibility
    , toggleChat
    , toggleDocTools
    , toggleDocumentStatus
    , toggleEditor
    , toggleExtrasSidebar
    , toggleGuide
    , toggleManuals
    , togglePublic
    , togglePublicUrl
    , toggleTOC
    , toggleTagsSidebar
    , workingDocs
    )

import Compiler.Util
import Config
import Document
import Element as E exposing (Element)
import Element.Background as Background
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import ExtractInfo
import Parser.Language exposing (Language(..))
import Predicate
import String.Extra
import Types exposing (AppMode(..), DocumentDeleteState(..), DocumentHandling, DocumentHardDeleteState(..), DocumentList(..), FrontendModel, FrontendMsg(..), MaximizedIndex(..), PopupState(..), PrintingState(..), SidebarExtrasState(..), SidebarTagsState(..), SignupState(..), SortMode(..), TagSelection(..))
import User exposing (User)
import Util
import View.Color as Color
import View.Style
import View.Utility


runNetworkModelCommand : Element FrontendMsg
runNetworkModelCommand =
    buttonTemplate [] RunNetworkModelCommand "Run command"


applyEdits : Element FrontendMsg
applyEdits =
    buttonTemplate [] ApplyEdits "Apply edits"


clearPassword : String -> Element FrontendMsg
clearPassword passwordString =
    if passwordString == "" then
        buttonTemplate [ Background.color (E.rgb 1 1 1), E.height (E.px 25) ] ClearPassword "x"

    else
        buttonTemplate [ Background.color (E.rgb 0.0 0.0 0.6), E.height (E.px 25) ] ClearPassword "x"



-- TEMPLATES


buttonTemplate : List (E.Attribute msg) -> msg -> String -> Element msg
buttonTemplate attrList msg label_ =
    E.row ([ View.Style.bgGray 0.2, E.pointer, E.mouseDown [ Background.color Color.darkRed ] ] ++ attrList)
        [ Input.button View.Style.buttonStyle
            { onPress = Just msg
            , label = E.el [ E.centerX, E.centerY, Font.size 14 ] (E.text label_)
            }
        ]


buttonTemplateWithTooltip : ButtonData -> Element FrontendMsg
buttonTemplateWithTooltip buttonData =
    E.row ([ View.Style.bgGray 0.2, E.pointer, E.mouseDown [ Background.color Color.darkRed ] ] ++ buttonData.attributes)
        [ Input.button View.Style.buttonStyle
            { onPress = Just buttonData.msg
            , label = View.Utility.addTooltip buttonData.tooltipPlacement buttonData.tooltipText (E.el [ E.centerX, E.centerY, Font.size 14 ] (E.text buttonData.label))
            }
        ]


buttonTemplateWithTooltip2 : ButtonData -> Element FrontendMsg
buttonTemplateWithTooltip2 buttonData =
    E.row ([ View.Style.bgGray 0.2, E.pointer, E.mouseDown [ Background.color Color.darkRed ] ] ++ buttonData.attributes)
        [ Input.button View.Style.buttonStyle
            { onPress = Just buttonData.msg
            , label = View.Utility.addTooltip buttonData.tooltipPlacement buttonData.tooltipText (E.el [ Font.color Color.black, E.centerX, E.centerY, Font.size 14 ] (E.text buttonData.label))
            }
        ]


type alias ButtonData =
    { tooltipText : String
    , tooltipPlacement : Element FrontendMsg -> E.Attribute FrontendMsg
    , attributes : List (E.Attribute FrontendMsg)
    , msg : FrontendMsg
    , label : String
    }


buttonTemplateSmall : List (E.Attribute msg) -> List (E.Attribute msg) -> msg -> String -> Element msg
buttonTemplateSmall attrList attrList2 msg label_ =
    E.row ([ View.Style.bgGray 0.2, E.pointer, E.mouseDown [ Background.color Color.darkRed ] ] ++ attrList)
        [ Input.button View.Style.buttonStyleSmall
            { onPress = Just msg
            , label = E.el ([ E.centerX, E.centerY, Font.size 12, E.paddingXY 2 2 ] ++ attrList2) (E.text label_)
            }
        ]


buttonTemplate2 : List (E.Attribute msg) -> msg -> String -> Element msg
buttonTemplate2 attrList msg label_ =
    E.row ([ E.pointer, E.mouseDown [ Background.color Color.lightBlue ] ] ++ attrList)
        [ Input.button View.Style.buttonStyle2
            { onPress = Just msg
            , label = E.el [ E.centerY, Font.size 16 ] (E.text label_)
            }
        ]


buttonTemplate3b : List (E.Attribute msg) -> List (E.Attribute msg) -> msg -> String -> Element msg
buttonTemplate3b attrList attrList2 msg label_ =
    E.row ([ E.pointer, E.mouseDown [ Background.color Color.lightBlue ] ] ++ attrList)
        [ Input.button View.Style.buttonStyle3
            { onPress = Just msg
            , label = E.el ([ E.centerY, Font.size 14 ] ++ attrList2) (E.text label_)
            }
        ]


buttonTemplate3 : List (E.Attribute msg) -> msg -> String -> Element msg
buttonTemplate3 attrList msg label_ =
    E.row ([ E.pointer, E.mouseDown [ Background.color Color.lightBlue ] ] ++ attrList)
        [ Input.button View.Style.buttonStyle3
            { onPress = Just msg
            , label = E.el [ E.centerY, Font.size 14, Font.color Color.blue ] (E.text label_)
            }
        ]


buttonTemplate4 : List (E.Attribute msg) -> msg -> String -> Element msg
buttonTemplate4 attrList msg label_ =
    E.row ([ E.pointer, E.mouseDown [ Background.color Color.lightBlue ] ] ++ attrList)
        [ Input.button View.Style.buttonStyleSmallWhite
            { onPress = Just msg
            , label = E.el [ E.centerY, Font.size 18, Font.color Color.white ] (E.text label_)
            }
        ]


linkTemplate : msg -> E.Color -> String -> Element msg
linkTemplate msg fontColor label_ =
    E.row [ E.pointer, E.mouseDown [ Background.color Color.paleBlue ] ]
        [ Input.button linkStyle
            { onPress = Just msg
            , label = E.el [ E.centerX, E.centerY, Font.size 14, Font.color fontColor ] (E.text label_)
            }
        ]


linkStyle =
    [ Font.color (E.rgb255 255 255 255)
    , E.paddingXY 8 2
    ]



-- UI
-- TOGGLES


toggleDocTools : FrontendModel -> Element FrontendMsg
toggleDocTools model =
    if model.showDocTools then
        buttonTemplate [] ToggleDocTools "Hide DocTools"

    else
        buttonTemplateWithTooltip
            { tooltipText = "Make backup, hide/show backups, ..."
            , tooltipPlacement = E.above
            , attributes = [ Font.color Color.white ]
            , msg = ToggleDocTools
            , label = "Show DocTools"
            }


toggleDocumentStatus : FrontendModel -> Element FrontendMsg
toggleDocumentStatus model =
    case model.currentDocument of
        Nothing ->
            E.none

        Just doc ->
            if Predicate.documentIsMineOrSharedToMe model.currentDocument model.currentUser then
                case doc.status of
                    Document.DSCanEdit ->
                        buttonTemplateWithTooltip
                            { tooltipText = "Toggle between 'Can edit' and 'Read only'"
                            , tooltipPlacement = E.above
                            , attributes = [ Font.color Color.white ]
                            , msg = SetDocumentStatus Document.DSReadOnly
                            , label = "Doc: Can Edit"
                            }

                    Document.DSReadOnly ->
                        buttonTemplateWithTooltip
                            { tooltipText = "Toggle between 'Can edit' and 'Read only'"
                            , tooltipPlacement = E.above
                            , attributes = [ Font.color Color.white ]
                            , msg = SetDocumentStatus Document.DSCanEdit
                            , label = "Doc: Read only"
                            }

                    Document.DSSoftDelete ->
                        buttonTemplate [] (SetDocumentStatus Document.DSCanEdit) "Doc: Soft-deleted"

            else
                E.none


editDocument : FrontendModel -> Element FrontendMsg
editDocument model =
    case model.currentDocument of
        Nothing ->
            E.none

        Just doc ->
            if Predicate.documentIsMineOrSharedToMe model.currentDocument model.currentUser then
                buttonTemplateWithTooltip
                    { tooltipText = "Toggle between 'Can edit' and 'Read only'"
                    , tooltipPlacement = E.above
                    , attributes = [ Font.color Color.white ]
                    , msg = SetDocumentStatus Document.DSCanEdit
                    , label = "Edit"
                    }

            else
                E.none


toggleBackupVisibility : Bool -> Element FrontendMsg
toggleBackupVisibility seeBackups =
    if seeBackups then
        buttonTemplate [] ToggleBackupVisibility "Backups visible"

    else
        buttonTemplate [] ToggleBackupVisibility "Backups hidden"


toggleGuide : Element FrontendMsg
toggleGuide =
    buttonTemplateWithTooltip
        { tooltipText = "Cheat sheet for the current markup language"
        , tooltipPlacement = E.below
        , attributes = [ Font.color Color.white ]
        , msg = ToggleManuals Types.TGuide
        , label = "Guide"
        }


toggleManuals : Element FrontendMsg
toggleManuals =
    buttonTemplateWithTooltip
        { tooltipText = "Manuals, templates, answers to common questions"
        , tooltipPlacement = E.below
        , attributes = [ Font.color Color.white ]
        , msg = ToggleManuals Types.TManual
        , label = "Manual"
        }


reply : String -> Types.UserMessage -> Element FrontendMsg
reply label usermessage =
    buttonTemplate [] (SendUserMessage usermessage) label


dismissUserMessage =
    buttonTemplate [ E.width (E.px 38) ] DismissUserMessage "x"


setLanguage : Bool -> Language -> Language -> String -> Element FrontendMsg
setLanguage dismiss currentLang targetLang targetLangString =
    let
        ( bg, fg ) =
            if currentLang == targetLang then
                ( Background.color Color.darkRed, Font.color Color.white )

            else
                ( Background.color (E.rgb 0 0 0), Font.color Color.white )
    in
    buttonTemplate [ bg, fg, E.width (E.px 100) ] (SetLanguage dismiss targetLang) targetLangString


setUserLanguage : Language -> Language -> String -> Element FrontendMsg
setUserLanguage currentLang targetLang targetLangString =
    let
        ( bg, fg ) =
            if currentLang == targetLang then
                ( Background.color Color.darkRed, Font.color Color.white )

            else
                ( Background.color (E.rgb 0 0 0), Font.color Color.white )
    in
    buttonTemplate [ bg, fg, E.width (E.px 100) ] (SetUserLanguage targetLang) targetLangString


languageMenu : PopupState -> Language -> Element FrontendMsg
languageMenu popupState lang =
    let
        langString =
            case lang of
                MicroLaTeXLang ->
                    "lang: µLaTeX"

                L0Lang ->
                    "lang: L0"

                PlainTextLang ->
                    "lang: Plain"

                XMarkdownLang ->
                    "lang: XMarkdown"
    in
    if popupState == NoPopup then
        buttonTemplateWithTooltip
            { tooltipText = "Set markup language of current document"
            , tooltipPlacement = E.above
            , attributes = [ Font.color Color.white ]
            , msg = ChangePopup LanguageMenuPopup
            , label = langString
            }

    else
        buttonTemplate [] (ChangePopup NoPopup) langString



-- DOCUMENT


share : Element FrontendMsg
share =
    buttonTemplateWithTooltip
        { tooltipText = "Share the current document"
        , tooltipPlacement = E.above
        , attributes = [ Font.color Color.white ]
        , msg = ShareDocument
        , label = "Share"
        }


doShare =
    buttonTemplate [] DoShare "Update"


startCollaborativeEditing : FrontendModel -> Element FrontendMsg
startCollaborativeEditing model =
    case model.collaborativeEditing of
        True ->
            buttonTemplate [] ToggleCollaborativeEditing "Collab: On"

        False ->
            buttonTemplate [] ToggleCollaborativeEditing "Collab: Off"



-- DELETE DOCUMENT


softDeleteDocument : FrontendModel -> Element FrontendMsg
softDeleteDocument model =
    let
        authorName : Maybe String
        authorName =
            Maybe.andThen .author model.currentDocument

        userName : Maybe String
        userName =
            Maybe.map .username model.currentUser
    in
    if userName /= Nothing && authorName == userName then
        case model.currentDocument of
            Nothing ->
                E.none

            Just doc ->
                case doc.status of
                    Document.DSSoftDelete ->
                        deleteDocument_ "Undelete" model

                    Document.DSCanEdit ->
                        deleteDocument_ "Delete" model

                    Document.DSReadOnly ->
                        buttonTemplate [ Background.color (E.rgb 0.5 0.5 0.5) ] FENoOp "Delete"

    else
        E.none


hardDeleteDocument : FrontendModel -> Element FrontendMsg
hardDeleteDocument model =
    let
        authorName : Maybe String
        authorName =
            Maybe.andThen .author model.currentDocument

        userName : Maybe String
        userName =
            Maybe.map .username model.currentUser
    in
    if userName /= Nothing && authorName == userName then
        case model.currentDocument of
            Nothing ->
                E.none

            Just doc ->
                case doc.status of
                    Document.DSSoftDelete ->
                        hardDelete "Hard delete" model

                    Document.DSCanEdit ->
                        E.none

                    Document.DSReadOnly ->
                        E.none

    else
        E.none


hardDelete title model =
    case model.hardDeleteDocumentState of
        WaitingForHardDeleteAction ->
            buttonTemplate [] (SetHardDeleteDocumentState CanHardDelete) title

        CanHardDelete ->
            buttonTemplate [ Background.color (E.rgb 0.8 0 0) ] HardDeleteDocument "Sure?"


deleteDocument_ title model =
    case model.deleteDocumentState of
        WaitingForDeleteAction ->
            buttonTemplate [] (SetDeleteDocumentState CanDelete) title

        CanDelete ->
            buttonTemplate [ Background.color (E.rgb 0.8 0 0) ] SoftDeleteDocument "Sure?"


cancelDeleteDocument model =
    case model.deleteDocumentState of
        WaitingForDeleteAction ->
            E.none

        CanDelete ->
            buttonTemplate [ Background.color (E.rgb 0 0 0.8) ] (SetDeleteDocumentState WaitingForDeleteAction) "Cancel"


makeBackup =
    buttonTemplate [] MakeBackup "Back up"


syncLR =
    buttonTemplate [] SendSyncLR "Sync"



--syncButton : Element Msg


syncButton : Element FrontendMsg
syncButton =
    buttonTemplate [] StartSync "Sync"


nextSyncButton : List a -> Element FrontendMsg
nextSyncButton foundIds =
    if List.length foundIds < 2 then
        E.none

    else
        buttonTemplate [] NextSync "Next sync"


toggleEditor model =
    let
        title =
            if model.showEditor then
                "Hide Editor"

            else
                "Show Editor"
    in
    buttonTemplate [ Background.color Color.darkBlue ] CloseEditor title


signOut model =
    case model.currentUser of
        Nothing ->
            E.none

        Just user ->
            buttonTemplate [] SignOut ("Sign out " ++ user.username)



-- DOCUMENT


getDocumentByPrivateId : Element FrontendMsg
getDocumentByPrivateId =
    buttonTemplate [] AskForDocumentByAuthorId "Get document"


setSortModeAlpha : SortMode -> Element FrontendMsg
setSortModeAlpha sortMode =
    let
        bg =
            case sortMode of
                SortAlphabetically ->
                    Background.color (E.rgb 0.5 0 0)

                SortByMostRecent ->
                    Background.color (E.rgb 0 0 0)
    in
    buttonTemplateSmall [ bg ] [ Font.size 10 ] (SetSortMode SortAlphabetically) "Alpha"


setSortModeMostRecent : SortMode -> Element FrontendMsg
setSortModeMostRecent sortMode =
    let
        bg =
            case sortMode of
                SortAlphabetically ->
                    Background.color (E.rgb 0 0 0)

                SortByMostRecent ->
                    Background.color (E.rgb 0.5 0 0)
    in
    buttonTemplateSmall [ bg ] [ Font.size 10 ] (SetSortMode SortByMostRecent) "Recent"


darkRed =
    E.rgb 0.475 0 0


charcoal =
    E.rgb 0.3 0.3 0.3


workingDocs currentDocumentList =
    if currentDocumentList == WorkingList then
        buttonTemplateSmall [ Background.color darkRed ] [ Font.size 10 ] FENoOp "Work "

    else
        buttonTemplateSmall [] [ Font.size 10 ] (SelectList WorkingList) "Work "


standardDocs currentDocumentList =
    if currentDocumentList == StandardList then
        buttonTemplateSmall [ Background.color darkRed ] [ Font.size 10 ] FENoOp "Docs "

    else
        buttonTemplateSmall [] [ Font.size 10 ] (SelectList StandardList) "Docs "


pinnedDocs currentDocumentList =
    if currentDocumentList == PinnedDocs then
        buttonTemplateSmall [ Background.color darkRed ] [ Font.size 10 ] FENoOp (String.fromChar '📌')

    else
        buttonTemplateSmall [] [ Font.size 10 ] (SelectList PinnedDocs) (String.fromChar '📌')


getPinnedDocs =
    buttonTemplateSmall [] [ Font.size 10 ] GetPinnedDocuments (String.fromChar '📌')


sharedDocs currentDocumentList =
    if currentDocumentList == SharedDocumentList then
        buttonTemplateSmall [ Background.color darkRed ] [] (SelectList SharedDocumentList) "Shared"

    else
        buttonTemplateSmall [ Background.color charcoal ] [] (SelectList SharedDocumentList) "Shared"



-- EXPORT


exportToMarkown : Element FrontendMsg
exportToMarkown =
    buttonTemplate [] ExportToMarkdown "Export to Markdown"


exportToLaTeX : Element FrontendMsg
exportToLaTeX =
    buttonTemplateWithTooltip
        { tooltipText = "Export to LaTeX file"
        , tooltipPlacement = E.above
        , attributes = [ Font.color Color.white ]
        , msg = ExportToLaTeX
        , label = "Export"
        }


exportToLaTeXRaw : Element FrontendMsg
exportToLaTeXRaw =
    buttonTemplateWithTooltip
        { tooltipText = "Export to raw LaTeX file (no preamble, etc)."
        , tooltipPlacement = E.above
        , attributes = [ Font.color Color.white ]
        , msg = ExportToRawLaTeX
        , label = "Raw"
        }


export : Element FrontendMsg
export =
    buttonTemplate [] Export "Export"


printToPDF : FrontendModel -> Element FrontendMsg
printToPDF model =
    case model.printingState of
        PrintWaiting ->
            buttonTemplate [ View.Utility.elementAttribute "title" "Generate PDF" ] PrintToPDF "PDF"

        PrintProcessing ->
            E.el [ Font.size 14, E.padding 8, E.height (E.px 30), Background.color Color.blue, Font.color Color.white ] (E.text "Please wait ...")

        PrintReady ->
            E.link
                [ Font.size 14
                , Background.color Color.white
                , E.paddingXY 8 8
                , Font.color Color.blue
                , Events.onClick (ChangePrintingState PrintWaiting)
                , View.Utility.elementAttribute "target" "_blank"
                ]
                { url = Config.pdfServer ++ "/pdf/" ++ (Maybe.map .id model.currentDocument |> Maybe.withDefault "???"), label = E.el [] (E.text "Click for PDF") }


createDocument : String -> Element FrontendMsg
createDocument title =
    if String.length title < 3 then
        buttonTemplate [ Background.color (E.rgb 0.7 0.7 0.7) ] NewDocument "Create"

    else
        buttonTemplate [] NewDocument "Create"


popupNewDocumentForm : PopupState -> Element FrontendMsg
popupNewDocumentForm popupState =
    case popupState of
        NoPopup ->
            buttonTemplate [] (ChangePopup NewDocumentPopup) "New"

        _ ->
            buttonTemplate [] (ChangePopup NoPopup) "New"


popupMonitor : PopupState -> Element FrontendMsg
popupMonitor popupState =
    case popupState of
        NoPopup ->
            buttonTemplate [] (ChangePopup NetworkMonitorPopup) "Monitor OFF"

        _ ->
            buttonTemplate [] (ChangePopup NoPopup) "Monitor ON"


dismissPopup : Element FrontendMsg
dismissPopup =
    buttonTemplate [] (ChangePopup NoPopup) "x"


dismissPublicUrlBox : Element FrontendMsg
dismissPublicUrlBox =
    buttonTemplate [ Background.color Color.lightBlue ] TogglePublicUrl "x"


closeEditor : Element FrontendMsg
closeEditor =
    buttonTemplate [] CloseEditor "Close Editor"


openEditor : Element FrontendMsg
openEditor =
    buttonTemplate [] OpenEditor "Open Editor"


runSpecial : Element FrontendMsg
runSpecial =
    buttonTemplate [] RunSpecial "Run Special"


help =
    buttonTemplate [] (Help Config.helpDocumentId) "Help"


startupHelp =
    buttonTemplate [] (Help Config.helpDocumentId) "Help"


experimentalMode mode =
    if mode then
        buttonTemplate [] ToggleExperimentalMode "Exp: ON"

    else
        buttonTemplate [] ToggleExperimentalMode "Exp: OFF"


signIn : Element FrontendMsg
signIn =
    buttonTemplate [] SignIn "Sign in"


signUp : Element FrontendMsg
signUp =
    buttonTemplate [] (SetSignupState ShowSignUpForm) "Sign up"


cancelSignUp : Element FrontendMsg
cancelSignUp =
    buttonTemplate [] (SetSignupState HideSignUpForm) "Cancel"


doSignUp : Element FrontendMsg
doSignUp =
    buttonTemplate [] SignUp "Sign up"



-- USER


sendUnlockMessage : FrontendModel -> Element FrontendMsg
sendUnlockMessage model =
    let
        currentUsername_ =
            Util.currentUsername model.currentUser
    in
    case model.currentDocument of
        Nothing ->
            E.none

        Just doc ->
            let
                editorNames =
                    doc.currentEditorList |> List.map .username
            in
            if List.member currentUsername_ editorNames then
                sendUnlockMessage_ doc model.currentUser

            else
                E.none


sendUnlockMessage_ doc currentUser =
    let
        message =
            { from = Util.currentUsername currentUser
            , to = "anon" -- TODO: nuke this?
            , subject = "Unlock?"
            , content = "May I unlock " ++ doc.title ++ "?"
            , show = [ Types.UMOk, Types.UMNotYet, Types.UMDismiss ]
            , info = doc.id
            , action = FENoOp
            , actionOnFailureToDeliver = Types.FAUnlockCurrentDocument
            }
    in
    buttonTemplateSmall [] [] (SendUserMessage message) "Ask to unlock"


clearConnectionDict =
    buttonTemplate [] Types.ClearConnectionDict "Clear ConnectionDict"


newFolder =
    buttonTemplate [] (Types.ChangePopup Types.FolderPopup) "New Folder"


createFolder =
    buttonTemplate [] Types.CreateFolder "Create Folder"


toggleAllowOpenFolder allowOpenFolder =
    if allowOpenFolder then
        buttonTemplateWithTooltip2
            { tooltipText = "Edit smart docs"
            , tooltipPlacement = E.below
            , attributes = [ Background.color Color.veryPaleBlue ]
            , msg = Types.ToggleAllowOpenFolder
            , label = "o"
            }

    else
        buttonTemplateWithTooltip2
            { tooltipText = "Activate smart docs"
            , tooltipPlacement = E.below
            , attributes = [ Background.color Color.veryPaleBlue ]
            , msg = Types.ToggleAllowOpenFolder
            , label = "e"
            }


toggleTOC : Bool -> Element FrontendMsg
toggleTOC showTOC =
    if showTOC then
        buttonTemplateSmall [] [ Font.size 18 ] ToggleTOC "-"

    else
        buttonTemplateSmall [] [ Font.size 12 ] ToggleTOC "+"


toggleActiveDocList : String -> Element FrontendMsg
toggleActiveDocList name =
    buttonTemplate2 [] ToggleActiveDocList name


togglePublicUrl : Element FrontendMsg
togglePublicUrl =
    buttonTemplateWithTooltip
        { tooltipText = "External link to public document"
        , tooltipPlacement = E.above
        , attributes = [ Font.color Color.white ]
        , msg = TogglePublicUrl
        , label = "Link"
        }



-- CHAT


clearChatHistory =
    buttonTemplate [ Background.color Color.medGray ] AskToClearChatHistory "Clear history"


makeCurrentGroupPreferred =
    buttonTemplate [ Background.color Color.medGray ] SetChatGroup "Set Group"


createChatGroup : Element FrontendMsg
createChatGroup =
    buttonTemplate [] CreateChatGroup "Create"


toggleChat : Element FrontendMsg
toggleChat =
    buttonTemplate [] ToggleChat "Chat"


setChatDisplay : FrontendModel -> Element FrontendMsg
setChatDisplay model =
    case model.chatDisplay of
        Types.TCGDisplay ->
            buttonTemplate [ Background.color Color.darkRed ] (Types.SetChatDisplay Types.TCGShowInputForm) "+"

        Types.TCGShowInputForm ->
            buttonTemplate [] (Types.SetChatDisplay Types.TCGDisplay) "Cancel"


setChatCreate : FrontendModel -> Element FrontendMsg
setChatCreate model =
    case model.chatDisplay of
        Types.TCGDisplay ->
            buttonTemplate [ Background.color Color.medGray ] (Types.SetChatDisplay Types.TCGShowInputForm) "Create group"

        Types.TCGShowInputForm ->
            buttonTemplate [ Background.color Color.darkRed ] (Types.SetChatDisplay Types.TCGDisplay) "Create group"


closeCollectionsIndex : Element FrontendMsg
closeCollectionsIndex =
    buttonTemplate2 [] CloseCollectionIndex "x"


getUserList : Element FrontendMsg
getUserList =
    buttonTemplate [] Types.GoGetUserList "Get users"


getUserTags : TagSelection -> Maybe User -> Element FrontendMsg
getUserTags tagSelection user =
    case user of
        Nothing ->
            E.none

        Just _ ->
            let
                style =
                    if tagSelection == TagUser then
                        [ Background.color Color.darkRed ]

                    else
                        []
            in
            buttonTemplate style GetUserTags "Tags"


getPublicTags : TagSelection -> Element FrontendMsg
getPublicTags tagSelection =
    let
        style =
            if tagSelection == TagPublic then
                [ Background.color Color.darkRed ]

            else
                []
    in
    buttonTemplate style GetPublicTags "Public tags"


toggleExtrasSidebar : SidebarExtrasState -> Element FrontendMsg
toggleExtrasSidebar sidebarState =
    case sidebarState of
        SidebarExtrasOut ->
            buttonTemplate [] ToggleExtrasSidebar (String.fromChar '⋮')

        SidebarExtrasIn ->
            buttonTemplateWithTooltip
                { tooltipText = "Show online users"
                , tooltipPlacement = E.below
                , attributes = [ Font.color Color.white ]
                , msg = ToggleExtrasSidebar
                , label = String.fromChar '⋮'
                }


toggleTagsSidebar : Types.SidebarTagsState -> Element FrontendMsg
toggleTagsSidebar sidebarState =
    case sidebarState of
        SidebarTagsOut ->
            buttonTemplate [] ToggleTagsSidebar "Tags"

        SidebarTagsIn ->
            -- buttonTemplate [] ToggleTagsSidebar "Tags"
            buttonTemplateWithTooltip
                { tooltipText = "List documents by tag"
                , tooltipPlacement = E.below
                , attributes = [ Font.color Color.white ]
                , msg = ToggleTagsSidebar
                , label = "Tags"
                }


maximizeMyDocs : MaximizedIndex -> Element FrontendMsg
maximizeMyDocs maximizedIndex =
    case maximizedIndex of
        MMyDocs ->
            buttonTemplate2 [] ToggleIndexSize "-"

        MPublicDocs ->
            buttonTemplate2 [] ToggleIndexSize "+"


maximizePublicDocs : MaximizedIndex -> Element FrontendMsg
maximizePublicDocs maximizedIndex =
    case maximizedIndex of
        MPublicDocs ->
            buttonTemplate2 [] ToggleIndexSize "-"

        MMyDocs ->
            buttonTemplate2 [] ToggleIndexSize "+"


home : Element FrontendMsg
home =
    buttonTemplate [] Home "Home"


iLink documentHandling id label =
    buttonTemplate [] (AskForDocumentById documentHandling id) label


getDocument : DocumentHandling -> String -> String -> Bool -> Element FrontendMsg
getDocument documentHandling id title highlighted =
    if highlighted then
        buttonTemplate3b [ Font.size 12 ] [ Font.color Color.darkRed ] (AskForDocumentById documentHandling id) title

    else
        buttonTemplate3b [ Font.size 12 ] [ Font.color Color.blue ] (AskForDocumentById documentHandling id) title


setDocumentAsCurrent : DocumentHandling -> Maybe Document.Document -> Document.Document -> Element FrontendMsg
setDocumentAsCurrent docHandling currentDocument document =
    let
        ( fg, weight ) =
            if currentDocument == Just document then
                -- red: document is current
                if document.status == Document.DSSoftDelete then
                    -- pale red: document has been soft-deleted
                    ( Font.color (E.rgb 0.7 0.4 0.4), Font.regular )

                else
                    ( Font.color (E.rgb 0.7 0 0), Font.semiBold )

            else if document.status == Document.DSSoftDelete then
                ( Font.color (E.rgb 0.5 0.5 0.5), Font.light )

            else
                ( Font.color (E.rgb 0 0 0.8), Font.regular )

        style =
            if document.public then
                Font.italic

            else
                Font.unitalicized

        titleString =
            case ExtractInfo.parseInfo "type" document.content of
                Nothing ->
                    document.title
                        |> Compiler.Util.compressWhitespace
                        |> String.Extra.ellipsisWith 40 " ..."

                Just _ ->
                    "["
                        ++ document.title
                        ++ "]"
                        |> Compiler.Util.compressWhitespace
                        |> String.Extra.ellipsisWith 40 " ..."
    in
    Input.button []
        { onPress = Just (SetDocumentAsCurrent docHandling document)
        , label = E.el [ Font.size 14, fg, weight, style ] (E.text titleString)
        }


{-| Use for document collections
-}
setDocAsCurrentWithDocInfo : Maybe Document.Document -> List Document.Document -> Document.DocumentInfo -> Element FrontendMsg
setDocAsCurrentWithDocInfo currentDocument documents docInfo =
    let
        username =
            Maybe.andThen .author currentDocument |> Maybe.withDefault "-"

        tags =
            Maybe.map .tags currentDocument |> Maybe.withDefault []

        docTag =
            List.filter (\item -> String.contains (username ++ ":") item) tags
                |> List.head

        fg =
            if Maybe.map .id currentDocument == Just docInfo.id then
                Font.color (E.rgb 0.7 0 0)

            else if docInfo.slug /= Nothing && docTag == docInfo.slug then
                Font.color (E.rgb 0.7 0 0)

            else
                Font.color (E.rgb 0 0 0.8)

        style =
            if docInfo.public then
                Font.italic

            else
                Font.unitalicized

        titleString =
            docInfo.title
                -- TODO: Find out why we need to compress blank spaces in the first place
                |> String.replace "   " " "
                |> String.replace "  " " "
                |> View.Utility.truncateString 40
    in
    Input.button []
        --{ onPress = Just (SetDocumentAsCurrent Types.CanEdit targetDocument)
        --, label = E.el [ Font.size 14, fg, style ] (E.text titleString)
        --}
        { onPress = Just (Fetch docInfo.id)
        , label = E.el [ Font.size 14, fg, style ] (E.text titleString)
        }


showTOCInPhone : Element FrontendMsg
showTOCInPhone =
    Input.button []
        { onPress = Just ShowTOCInPhone
        , label = E.el [ E.centerX, E.centerY, Font.size 18 ] (E.text "Index")
        }


setDocumentInPhoneAsCurrent : DocumentHandling -> Maybe Document.Document -> Document.Document -> Element FrontendMsg
setDocumentInPhoneAsCurrent docPermissions currentDocument document =
    let
        fg =
            if currentDocument == Just document then
                Font.color (E.rgb 0.7 0 0)

            else
                Font.color (E.rgb 0 0 0.8)

        style =
            if document.public then
                Font.italic

            else
                Font.unitalicized
    in
    Input.button []
        { onPress = Just (SetDocumentInPhoneAsCurrent docPermissions document)
        , label = E.el [ E.centerX, E.centerY, Font.size 14, fg, style ] (E.text document.title)
        }


togglePublic : Maybe Document.Document -> Element FrontendMsg
togglePublic maybeDoc =
    case maybeDoc of
        Nothing ->
            E.none

        Just doc ->
            case doc.public of
                False ->
                    buttonTemplateWithTooltip
                        { tooltipText = "Toggle document access (public/private)"
                        , tooltipPlacement = E.below
                        , attributes = [ Font.color Color.white ]
                        , msg = SetPublic doc True
                        , label = "Private"
                        }

                True ->
                    buttonTemplateWithTooltip
                        { tooltipText = "Toggle document access (public/private)"
                        , tooltipPlacement = E.below
                        , attributes = [ Font.color Color.white ]
                        , msg = SetPublic doc False
                        , label = "Public"
                        }


toggleAppMode : FrontendModel -> Element FrontendMsg
toggleAppMode model =
    case model.appMode of
        UserMode ->
            buttonTemplate [] (SetAppMode AdminMode) "User Mode"

        AdminMode ->
            buttonTemplate [] (SetAppMode UserMode) "Admin Mode"
