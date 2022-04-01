module View.Button exposing
    ( cancelDeleteDocument
    , cancelSignUp
    , closeCollectionsIndex
    , closeEditor
    , createDocument
    , deleteDocument
    , doSignUp
    , export
    , exportToLaTeX
    , exportToMarkown
    , exportToMicroLaTeX
    , exportToXMarkdown
    , getDocument
    , getDocumentByPrivateId
    , getPublicTags
    , getUserTags
    , help
    , home
    , iLink
    , languageMenu
    , linkTemplate
    , maximizeMyDocs
    , maximizePublicDocs
    , nextSyncButton
    , openEditor
    , popupNewDocumentForm
    , printToPDF
    , runSpecial
    , setDocumentAsCurrent
    , setDocumentInPhoneAsCurrent
    , setLanguage
    , setSortModeAlpha
    , setSortModeMostRecent
    , setUserLanguage
    , showTOCInPhone
    , signIn
    , signOut
    , signUp
    , startupHelp
    , syncButton
    , syncLR
    , toggleActiveDocList
    , toggleAppMode
    , toggleDocumentList
    , toggleEditor
    , togglePublic
    , toggleSidebar
    )

import Config
import Document
import Element as E exposing (Element)
import Element.Background as Background
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Parser.Language exposing (Language(..))
import Types exposing (AppMode(..), DocPermissions, DocumentDeleteState(..), DocumentList(..), FrontendModel, FrontendMsg(..), MaximizedIndex(..), PopupState(..), PrintingState(..), SidebarState(..), SignupState(..), SortMode(..), TagSelection(..))
import User exposing (User)
import View.Color as Color
import View.Style
import View.Utility



-- TEMPLATES


buttonTemplate : List (E.Attribute msg) -> msg -> String -> Element msg
buttonTemplate attrList msg label_ =
    E.row ([ View.Style.bgGray 0.2, E.pointer, E.mouseDown [ Background.color Color.darkRed ] ] ++ attrList)
        [ Input.button View.Style.buttonStyle
            { onPress = Just msg
            , label = E.el [ E.centerX, E.centerY, Font.size 14 ] (E.text label_)
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


buttonTemplate3 : List (E.Attribute msg) -> msg -> String -> Element msg
buttonTemplate3 attrList msg label_ =
    E.row ([ E.pointer, E.mouseDown [ Background.color Color.lightBlue ] ] ++ attrList)
        [ Input.button View.Style.buttonStyle3
            { onPress = Just msg
            , label = E.el [ E.centerY, Font.size 14, Font.color Color.blue ] (E.text label_)
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


exportToMicroLaTeX =
    buttonTemplate [] (ExportTo MicroLaTeXLang) "Export to MicroLaTeX"


exportToXMarkdown =
    buttonTemplate [] (ExportTo XMarkdownLang) "Export to XMarkdown"


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
        buttonTemplate [] (ChangePopup LanguageMenuPopup) langString

    else
        buttonTemplate [] (ChangePopup NoPopup) langString


deleteDocument : FrontendModel -> Element FrontendMsg
deleteDocument model =
    let
        authorName : Maybe String
        authorName =
            Maybe.andThen .author model.currentDocument

        userName : Maybe String
        userName =
            Maybe.map .username model.currentUser
    in
    if userName /= Nothing && authorName == userName then
        deleteDocument_ model
        --else if userName == Just "jxxcarlson" then
        --    deleteDocument_ model

    else
        E.none



--if Maybe.map .author model.currentDocument == Maybe.andThen .username model.currentUser then
--    deleteDocument_ model
--
--else
--    E.none


deleteDocument_ model =
    case model.deleteDocumentState of
        WaitingForDeleteAction ->
            buttonTemplate [] (SetDeleteDocumentState CanDelete) "Delete"

        CanDelete ->
            buttonTemplate [ Background.color (E.rgb 0.8 0 0) ] DeleteDocument "Forever?"


cancelDeleteDocument model =
    case model.deleteDocumentState of
        WaitingForDeleteAction ->
            E.none

        CanDelete ->
            buttonTemplate [ Background.color (E.rgb 0 0 0.8) ] (SetDeleteDocumentState WaitingForDeleteAction) "Cancel"


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


sortButtonWidth =
    143


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
    buttonTemplate [ bg, E.width (E.px 80) ] (SetSortMode SortAlphabetically) "Alpha"


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
    buttonTemplate [ bg ] (SetSortMode SortByMostRecent) "Most recent"


toggleDocumentList currentDocumentList =
    case currentDocumentList of
        WorkingList ->
            buttonTemplate [ E.width (E.px 90) ] (SelectList StandardList) "Work"

        StandardList ->
            buttonTemplate [ E.width (E.px 90) ] (SelectList WorkingList) "Standard"



-- EXPORT


exportToMarkown : Element FrontendMsg
exportToMarkown =
    buttonTemplate [] ExportToMarkdown "Export to Markdown"


exportToLaTeX : Element FrontendMsg
exportToLaTeX =
    buttonTemplate [] ExportToLaTeX "Export to LaTeX"


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


createDocument : Element FrontendMsg
createDocument =
    buttonTemplate [] NewDocument "Create"


popupNewDocumentForm : PopupState -> Element FrontendMsg
popupNewDocumentForm popupState =
    case popupState of
        NoPopup ->
            buttonTemplate [] (ChangePopup NewDocumentPopup) "New"

        _ ->
            buttonTemplate [] (ChangePopup NoPopup) "New"


closeEditor : Element FrontendMsg
closeEditor =
    buttonTemplate [] CloseEditor "Close Editor"


openEditor : Element FrontendMsg
openEditor =
    buttonTemplate [] OpenEditor "Edit"


runSpecial : Element FrontendMsg
runSpecial =
    buttonTemplate [] RunSpecial "Run Special"


help =
    buttonTemplate [] (Help Config.helpDocumentId) "Help"


startupHelp =
    buttonTemplate [] (Help Config.startupHelpDocumentId) "Help"


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
    buttonTemplate [] DoSignUp "Sign up"



-- USER


toggleActiveDocList : String -> Element FrontendMsg
toggleActiveDocList name =
    buttonTemplate2 [] ToggleActiveDocList name


closeCollectionsIndex : Element FrontendMsg
closeCollectionsIndex =
    buttonTemplate2 [] CloseCollectionIndex "x"


getUserTags : TagSelection -> Maybe User -> Element FrontendMsg
getUserTags tagSelection user =
    case user of
        Nothing ->
            E.none

        Just user_ ->
            let
                style =
                    if tagSelection == TagUser then
                        [ Background.color Color.darkRed ]

                    else
                        []
            in
            buttonTemplate style (GetUserTags user_.username) "Tags"


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


toggleSidebar : SidebarState -> Element FrontendMsg
toggleSidebar sidebarState =
    case sidebarState of
        SidebarOut ->
            buttonTemplate [] ToggleSideBar (String.fromChar '⋮')

        SidebarIn ->
            buttonTemplate [] ToggleSideBar (String.fromChar '⋮')


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


iLink id label =
    buttonTemplate [] (Fetch id) label


getDocument : String -> String -> Element FrontendMsg
getDocument id title =
    buttonTemplate3 [ Font.size 12, Font.color Color.blue ] (AskFoDocumentById id) title


setDocumentAsCurrent : DocPermissions -> Maybe Document.Document -> Document.Document -> Element FrontendMsg
setDocumentAsCurrent docPermissions currentDocument document =
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

        titleString =
            document.title
                -- TODO: Find out why we need to compress blank spaces in the first place
                |> String.replace "   " " "
                |> String.replace "  " " "
                |> View.Utility.truncateString 40
    in
    Input.button []
        { onPress = Just (SetDocumentAsCurrent docPermissions document)
        , label = E.el [ Font.size 14, fg, style ] (E.text titleString)
        }


showTOCInPhone : Element FrontendMsg
showTOCInPhone =
    Input.button []
        { onPress = Just ShowTOCInPhone
        , label = E.el [ E.centerX, E.centerY, Font.size 18 ] (E.text "Index")
        }


setDocumentInPhoneAsCurrent : DocPermissions -> Maybe Document.Document -> Document.Document -> Element FrontendMsg
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
                    buttonTemplate [] (SetPublic doc True) "Private"

                True ->
                    buttonTemplate [] (SetPublic doc False) "Public"


toggleAppMode : FrontendModel -> Element FrontendMsg
toggleAppMode model =
    case model.appMode of
        UserMode ->
            buttonTemplate [] (SetAppMode AdminMode) "User Mode"

        AdminMode ->
            buttonTemplate [] (SetAppMode UserMode) "Admin Mode"



-- buttonTemplate [ Font.size 14, fg, Background.color (E.rgb 0.3 0.3 0.3) ] (SetDocumentAsCurrent document) document.title
