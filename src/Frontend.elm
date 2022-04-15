module Frontend exposing (Model, app, changePrintingState, exportDoc, exportToLaTeX, fixId_, init, issueCommandIfDefined, subscriptions, update, updateDoc, updateFromBackend, urlAction, urlIsForGuest, view)

import Browser.Events
import Browser.Navigation as Nav
import Chat
import Cmd.Extra exposing (withNoCmd)
import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Debounce
import Dict
import Docs
import Document
import DocumentTools
import Element
import File.Download as Download
import Frontend.Cmd
import Frontend.PDF as PDF
import Frontend.Update
import Html
import Keyboard
import Lamdera exposing (sendToBackend)
import Markup
import Message
import Parser.Language exposing (Language(..))
import Process
import Render.MicroLaTeX
import Render.XMarkdown
import Share
import Task
import Time
import Types exposing (ActiveDocList(..), AppMode(..), DocLoaded(..), DocumentDeleteState(..), DocumentHandling(..), DocumentList(..), FrontendModel, FrontendMsg(..), MaximizedIndex(..), MessageStatus(..), PhoneMode(..), PopupState(..), PopupStatus(..), PrintingState(..), SidebarExtrasState(..), SidebarTagsState(..), SignupState(..), SortMode(..), TagSelection(..), ToBackend(..), ToFrontend(..))
import Url exposing (Url)
import UrlManager
import User
import Util
import View.Chat
import View.Main
import View.Phone
import View.Utility


type alias Model =
    FrontendModel


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        }


subscriptions _ =
    Sub.batch
        [ Browser.Events.onResize (\w h -> GotNewWindowDimensions w h)
        , Time.every (Config.frontendTickSeconds * 1000) FETick
        , Sub.map KeyMsg Keyboard.subscriptions
        ]


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    ( { key = key
      , url = url
      , messages = [ { content = "Welcome!", status = MSWhite } ]
      , currentTime = Time.millisToPosix 0
      , zone = Time.utc

      -- ADMIN
      , statusReport = []
      , inputSpecial = ""
      , userList = []
      , connectedUsers = []
      , sharedDocumentList = []

      -- USER
      , userMessage = Nothing
      , currentUser = Nothing
      , inputUsername = ""
      , inputPassword = ""
      , inputPasswordAgain = ""
      , inputEmail = ""
      , inputRealname = ""
      , tagDict = Dict.empty
      , publicTagDict = Dict.empty
      , inputLanguage = L0Lang
      , documentList = StandardList

      -- CHAT (FrontendModel)
      , chatDisplay = Types.TCGDisplay
      , inputGroupMembers = ""
      , inputGroupName = ""
      , inputGroupAssistant = ""
      , chatMessageFieldContent = ""
      , chatMessages = []
      , chatVisible = False
      , inputGroup = ""
      , currentChatGroup = Nothing

      -- UI
      , appMode = UserMode
      , windowWidth = 600
      , windowHeight = 900
      , popupStatus = PopupClosed
      , showEditor = False
      , phoneMode = PMShowDocumentList
      , pressedKeys = []
      , activeDocList = Both
      , maximizedIndex = MPublicDocs
      , sidebarExtrasState = SidebarExtrasIn
      , sidebarTagsState = SidebarTagsIn
      , tagSelection = TagPublic
      , signupState = HideSignUpForm
      , popupState = NoPopup

      -- SYNC
      , doSync = False
      , docLoaded = NotLoaded
      , linenumber = 0
      , foundIds = []
      , foundIdIndex = 0
      , selectedId = ""
      , searchCount = 0
      , searchSourceText = ""
      , syncRequestIndex = 0

      -- DOCUMENT
      , lineNumber = 0
      , permissions = StandardHandling
      , initialText = Config.loadingText
      , documentsCreatedCounter = 0
      , sourceText = Config.loadingText
      , editRecord = Compiler.DifferentialParser.init L0Lang Config.loadingText
      , title = "Loading ..."
      , tableOfContents = Compiler.ASTTools.tableOfContents (Markup.parse L0Lang Config.loadingText)
      , debounce = Debounce.init
      , counter = 0
      , inputSearchKey = ""
      , actualSearchKey = ""
      , inputSearchTagsKey = ""
      , publicDocumentSearchKey = Config.publicDocumentStartupSearchKey
      , authorId = ""
      , documents = []
      , currentDocument = Just Docs.notSignedIn
      , currentCheatsheet = Nothing
      , currentMasterDocument = Nothing
      , printingState = PrintWaiting
      , documentDeleteState = WaitingForDeleteAction
      , publicDocuments = []
      , deleteDocumentState = WaitingForDeleteAction
      , sortMode = SortAlphabetically
      , language = Config.initialLanguage
      , inputTitle = ""
      , inputReaders = ""
      , inputEditors = ""
      }
    , Cmd.batch
        [ Frontend.Cmd.setupWindow
        , urlAction url.path
        , sendToBackend (SearchForDocuments Nothing "system:startup")
        , Task.perform AdjustTimeZone Time.here
        , sendToBackend GetCheatSheetDocument
        ]
    )


urlAction : String -> Cmd FrontendMsg
urlAction path =
    let
        prefix =
            String.left 3 path

        segment =
            String.dropLeft 3 path
    in
    if prefix == "/" then
        sendToBackend (GetDocumentById Types.StandardHandling Config.welcomeDocId)

    else
        case prefix of
            "/i/" ->
                sendToBackend (GetDocumentById Types.StandardHandling segment)

            "/a/" ->
                sendToBackend (SearchForDocumentsWithAuthorAndKey segment)

            "/s/" ->
                sendToBackend (SearchForDocuments Nothing segment)

            "/h/" ->
                sendToBackend (GetHomePage segment)

            _ ->
                --Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById id))
                sendToBackend (GetDocumentById Types.StandardHandling Config.welcomeDocId)


urlIsForGuest : Url -> Bool
urlIsForGuest url =
    String.left 2 url.path == "/g"


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        FENoOp ->
            ( model, Cmd.none )

        FETick newTime ->
            ( { model | currentTime = newTime }, Cmd.none )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }, Cmd.none )

        GotTime timeNow ->
            ( model, Cmd.none )

        KeyMsg keyMsg ->
            Frontend.Update.updateKeys model keyMsg

        UrlClicked urlRequest ->
            Frontend.Update.handleUrlRequest model urlRequest

        UrlChanged url ->
            let
                cmd =
                    if String.left 3 url.path == "/c/" then
                        Util.delay 1 (SetDocumentCurrentViaId (String.dropLeft 3 url.path))

                    else
                        UrlManager.handleDocId url
            in
            ( { model | url = url }, cmd )

        -- CHAT (update)
        AskToClearChatHistory ->
            ( model, sendToBackend (ClearChatHistory model.inputGroup) )

        MakeCurrentChatGroupPreferred ->
            case model.currentUser of
                Nothing ->
                    ( model, Cmd.none )

                Just user ->
                    let
                        oldPreferences =
                            user.preferences

                        revisedPreferences =
                            if String.trim model.inputGroup == "" then
                                { oldPreferences | group = Nothing }

                            else
                                { oldPreferences | group = Just (String.trim model.inputGroup) }

                        revisedUser =
                            { user | preferences = revisedPreferences }
                    in
                    ( { model | currentUser = Just revisedUser }, sendToBackend (UpdateUserWith revisedUser) )

        GetChatHistory ->
            ( model, Cmd.batch [ sendToBackend (SendChatHistory model.inputGroup) ] )

        ScrollChatToBottom ->
            ( model, View.Chat.scrollChatToBottom )

        CreateChatGroup ->
            case model.currentUser of
                Nothing ->
                    ( { model | chatDisplay = Types.TCGDisplay }, Cmd.none )

                Just user ->
                    let
                        newChatGroup =
                            { name = model.inputGroupName
                            , owner = user.username
                            , assistant = Just model.inputGroupAssistant
                            , members = model.inputGroupMembers |> String.split "," |> List.map String.trim
                            }
                    in
                    ( { model | chatDisplay = Types.TCGDisplay, currentChatGroup = Just newChatGroup }, sendToBackend (InsertChatGroup newChatGroup) )

        SetChatDisplay option ->
            ( { model | chatDisplay = option }, Cmd.none )

        InputGroupName str ->
            ( { model | inputGroupName = str }, Cmd.none )

        InputGroupAssistant str ->
            ( { model | inputGroupAssistant = str }, Cmd.none )

        InputGroupMembers str ->
            ( { model | inputGroupMembers = str }, Cmd.none )

        InputChoseGroup str ->
            ( { model | inputGroup = str }, sendToBackend (GetChatGroup str) )

        ToggleChat ->
            ( { model | chatVisible = not model.chatVisible }, Util.delay 100 ScrollChatToBottom )

        MessageFieldChanged str ->
            ( { model | chatMessageFieldContent = str }, Cmd.none )

        -- User has hit the Send button
        MessageSubmitted ->
            let
                chatMessage =
                    { sender = model.currentUser |> Maybe.map .username |> Maybe.withDefault "anon"
                    , group = model.inputGroup
                    , subject = ""
                    , content = model.chatMessageFieldContent
                    , date = model.currentTime
                    }
            in
            ( { model | chatMessageFieldContent = "", messages = model.messages }
            , Cmd.batch
                [ Lamdera.sendToBackend (ChatMsgSubmitted chatMessage)
                , View.Chat.focusMessageInput
                , View.Chat.scrollChatToBottom
                ]
            )

        -- USER
        DismissUserMessage ->
            ( { model | userMessage = Nothing }, Cmd.none )

        SendUserMessage message ->
            ( { model | userMessage = Nothing }, sendToBackend (DeliverUserMessage message) )

        OpenSharedDocumentList ->
            ( model
            , sendToBackend (GetSharedDocuments (model.currentUser |> Maybe.map .username |> Maybe.withDefault "(anon)"))
            )

        SetSignupState state ->
            ( { model
                | signupState = state
                , inputUsername = ""
                , inputPassword = ""
                , inputPasswordAgain = ""
                , inputEmail = ""
                , inputRealname = ""
              }
            , Cmd.none
            )

        DoSignUp ->
            Frontend.Update.handleSignUp model

        SignIn ->
            Frontend.Update.handleSignIn model

        SignOut ->
            Frontend.Update.handleSignOut model

        -- ADMIN
        ClearConnectionDict ->
            ( model, sendToBackend ClearConnectionDictBE )

        GoGetUserList ->
            ( model, sendToBackend GetUserList )

        InputSpecial str ->
            { model | inputSpecial = str } |> withNoCmd

        RunSpecial ->
            Frontend.Update.runSpecial model

        InputUsername str ->
            ( { model | inputUsername = str }, Cmd.none )

        InputPassword str ->
            ( { model | inputPassword = str }, Cmd.none )

        InputPasswordAgain str ->
            ( { model | inputPasswordAgain = str }, Cmd.none )

        InputRealname str ->
            ( { model | inputRealname = str }, Cmd.none )

        InputEmail str ->
            ( { model | inputEmail = str }, Cmd.none )

        -- UI
        ToggleCheatsheet ->
            case model.popupState of
                NoPopup ->
                    let
                        id =
                            case model.language of
                                L0Lang ->
                                    Config.l0CheetsheetId

                                MicroLaTeXLang ->
                                    Config.microLaTeXCheetsheetId

                                XMarkdownLang ->
                                    Config.xmarkdownCheetsheetId

                                PlainTextLang ->
                                    Config.plainTextCheetsheetId
                    in
                    ( { model | popupState = CheatSheetPopup }, sendToBackend (FetchDocumentById HandleAsCheatSheet id) )

                _ ->
                    ( { model | popupState = NoPopup }, Cmd.none )

        SelectList list ->
            let
                cmd =
                    if list == SharedDocumentList then
                        sendToBackend (GetSharedDocuments (model.currentUser |> Maybe.map .username |> Maybe.withDefault "(anon)"))

                    else
                        Cmd.none
            in
            ( { model | documentList = list }, cmd )

        ChangePopup popupState ->
            ( { model | popupState = popupState }, Cmd.none )

        ToggleIndexSize ->
            case model.maximizedIndex of
                MMyDocs ->
                    ( { model | maximizedIndex = MPublicDocs }, Cmd.none )

                MPublicDocs ->
                    ( { model | maximizedIndex = MMyDocs }, Cmd.none )

        CloseCollectionIndex ->
            ( { model | currentMasterDocument = Nothing }
            , Cmd.none
            )

        ToggleActiveDocList ->
            case model.currentMasterDocument of
                Nothing ->
                    ( { model | activeDocList = Both }, Cmd.none )

                Just _ ->
                    case model.activeDocList of
                        PublicDocsList ->
                            ( { model | activeDocList = PrivateDocsList }, Cmd.none )

                        PrivateDocsList ->
                            ( { model | activeDocList = PublicDocsList }, Cmd.none )

                        Both ->
                            ( { model | activeDocList = PrivateDocsList }, Cmd.none )

        Home ->
            ( model, sendToBackend (GetDocumentById Types.StandardHandling Config.welcomeDocId) )

        ShowTOCInPhone ->
            ( { model | phoneMode = PMShowDocumentList }, Cmd.none )

        SetDocumentInPhoneAsCurrent permissions doc ->
            Frontend.Update.setDocumentInPhoneAsCurrent model doc permissions

        SetAppMode appMode ->
            let
                cmd =
                    case appMode of
                        UserMode ->
                            Cmd.none

                        AdminMode ->
                            sendToBackend GetUserList
            in
            ( { model | appMode = appMode }, cmd )

        GotNewWindowDimensions w h ->
            ( { model | windowWidth = w, windowHeight = h }, Cmd.none )

        GotViewport vp ->
            Frontend.Update.updateWithViewport vp model

        SetViewPortForElement result ->
            Frontend.Update.setViewportForElement model result

        InputSearchSource str ->
            ( { model | searchSourceText = str, foundIdIndex = 0 }, Cmd.none )

        GetSelection str ->
            ( { model | messages = [ { content = "Selection: " ++ str, status = MSWhite } ] }, Cmd.none )

        -- SYNC
        SelectedText str ->
            Frontend.Update.firstSyncLR model str

        SendSyncLR ->
            ( { model | syncRequestIndex = model.syncRequestIndex + 1 }, Cmd.none )

        SyncLR ->
            Frontend.Update.syncLR model

        StartSync ->
            ( { model | doSync = not model.doSync }, Cmd.none )

        NextSync ->
            Frontend.Update.nextSyncLR model

        ChangePopupStatus status ->
            ( { model | popupStatus = status }, Cmd.none )

        NoOpFrontendMsg ->
            ( model, Cmd.none )

        CloseEditor ->
            Frontend.Update.closeEditor model

        OpenEditor ->
            case model.currentDocument of
                Nothing ->
                    ( { model | messages = [ { content = "No document to open in editor", status = MSWhite } ] }, Cmd.none )

                Just doc ->
                    Frontend.Update.openEditor doc model

        Help docId ->
            ( model, sendToBackend (SearchForDocumentsWithAuthorAndKey docId) )

        -- SHARE
        Narrow username document ->
            ( model, sendToBackend (Narrowcast username document) )

        LockCurrentDocument ->
            Frontend.Update.lockDocument model

        UnLockCurrentDocument ->
            Frontend.Update.unlockCurrentDocument model

        -- DOCUMENT
        SetDocumentCurrent document ->
            Frontend.Update.setDocumentAsCurrent model document HandleAsCheatSheet

        InputReaders str ->
            ( { model | inputReaders = str }, Cmd.none )

        InputEditors str ->
            ( { model | inputEditors = str }, Cmd.none )

        ShareDocument ->
            Share.shareDocument model

        DoShare ->
            Share.doShare model

        GetPinnedDocuments ->
            ( { model | documentList = StandardList }, sendToBackend (SearchForDocuments (model.currentUser |> Maybe.map .username) "pin") )

        -- TAGS
        GetUserTags ->
            ( { model | tagSelection = TagUser }, Cmd.none )

        GetPublicTags ->
            ( { model | tagSelection = TagPublic }, Cmd.none )

        ToggleExtrasSidebar ->
            case model.sidebarExtrasState of
                SidebarExtrasIn ->
                    ( { model | sidebarExtrasState = SidebarExtrasOut, sidebarTagsState = SidebarTagsIn }
                    , sendToBackend GetUsersWithOnlineStatus
                    )

                SidebarExtrasOut ->
                    ( { model | sidebarExtrasState = SidebarExtrasIn }, Cmd.none )

        ToggleTagsSidebar ->
            let
                tagSelection =
                    model.tagSelection
            in
            case model.sidebarTagsState of
                SidebarTagsIn ->
                    ( { model | sidebarExtrasState = SidebarExtrasIn, sidebarTagsState = SidebarTagsOut }
                    , Cmd.batch
                        [ sendToBackend GetPublicTagsFromBE
                        , sendToBackend (GetUserTagsFromBE (Util.currentUsername model.currentUser))
                        ]
                    )

                SidebarTagsOut ->
                    ( { model | messages = Message.make "Tags in" MSYellow, tagSelection = tagSelection, sidebarTagsState = SidebarTagsIn }, Cmd.none )

        SetLanguage dismiss lang ->
            Frontend.Update.setLanguage dismiss lang model

        SetUserLanguage lang ->
            Frontend.Update.setUserLanguage lang model

        Render msg_ ->
            Frontend.Update.render model msg_

        Fetch id ->
            ( model, sendToBackend (FetchDocumentById StandardHandling id) )

        DebounceMsg msg_ ->
            Frontend.Update.debounceMsg model msg_

        Saved str ->
            updateDoc model str

        Search ->
            ( { model
                | actualSearchKey = model.inputSearchKey
                , documentList = StandardList
                , currentMasterDocument = Nothing
              }
            , sendToBackend (SearchForDocuments (model.currentUser |> Maybe.map .username) model.inputSearchKey)
            )

        SearchText ->
            Frontend.Update.searchText model

        InputText str ->
            Frontend.Update.inputText model str

        InputTitle str ->
            Frontend.Update.inputTitle model str

        SetInitialEditorContent ->
            Frontend.Update.setInitialEditorContent model

        InputAuthorId str ->
            ( { model | authorId = str }, Cmd.none )

        AskForDocumentById documentHandling id ->
            ( model, sendToBackend (GetDocumentById documentHandling id) )

        AskForDocumentByAuthorId ->
            ( model, sendToBackend (SearchForDocumentsWithAuthorAndKey model.authorId) )

        InputSearchKey str ->
            ( { model | inputSearchKey = str }, Cmd.none )

        InputSearchTagsKey str ->
            ( { model | inputSearchTagsKey = str }, Cmd.none )

        NewDocument ->
            Frontend.Update.newDocument model

        SetDeleteDocumentState s ->
            ( { model | deleteDocumentState = s }, Cmd.none )

        DeleteDocument ->
            Frontend.Update.deleteDocument model

        SetPublicDocumentAsCurrentById id ->
            Frontend.Update.setPublicDocumentAsCurrentById model id

        SetDocumentAsCurrent permissions doc ->
            Frontend.Update.setDocumentAsCurrent model doc permissions

        SetDocumentCurrentViaId id ->
            case Document.documentFromListViaId id model.documents of
                Nothing ->
                    ( model, Cmd.none )

                Just doc ->
                    ( Frontend.Update.currentDocumentPostProcess doc model, Cmd.none )

        SetPublic doc public ->
            Frontend.Update.setPublic model doc public

        SetSortMode sortMode ->
            ( { model | sortMode = sortMode }, Cmd.none )

        -- Export
        ExportToMarkdown ->
            Frontend.Update.exportToMarkdown model

        ExportToLaTeX ->
            Frontend.Update.exportToLaTeX model

        ExportTo lang ->
            case model.currentDocument of
                Nothing ->
                    ( model, Cmd.none )

                Just doc ->
                    case lang of
                        MicroLaTeXLang ->
                            let
                                ast =
                                    model.editRecord.parsed

                                newText =
                                    Render.MicroLaTeX.export ast
                            in
                            ( model, Download.string "out-microlatex.txt" "text/plain" newText )

                        L0Lang ->
                            ( model, Download.string "out-l0.txt" "text/plain" doc.content )

                        PlainTextLang ->
                            ( model, Download.string "out-l0.txt" "text/plain" doc.content )

                        XMarkdownLang ->
                            let
                                ast =
                                    model.editRecord.parsed

                                newText =
                                    Render.XMarkdown.export ast
                            in
                            ( model, Download.string "out-xmarkdown.txt" "text/plain" newText )

        Export ->
            issueCommandIfDefined model.currentDocument model exportDoc

        PrintToPDF ->
            PDF.print model

        GotPdfLink result ->
            PDF.gotLink model result

        ChangePrintingState printingState ->
            -- TODO: review this
            issueCommandIfDefined model.currentDocument { model | printingState = printingState } (changePrintingState printingState)

        FinallyDoCleanPrintArtefacts _ ->
            ( model, Cmd.none )


fixId_ : String -> String
fixId_ str =
    -- TODO: Review this. We should not have to do this
    let
        parts =
            String.split "." str
    in
    case
        List.head parts
    of
        Nothing ->
            str

        Just prefix ->
            let
                p =
                    String.toInt prefix |> Maybe.withDefault 0 |> (\x -> x + 1) |> String.fromInt
            in
            (p :: List.drop 1 parts) |> String.join "."


updateDoc model str =
    case model.currentDocument of
        Nothing ->
            ( model, Cmd.none )

        Just doc ->
            -- if Share.canEdit model.currentUser (Just doc) then
            -- if View.Utility.canSaveStrict model.currentUser doc then
            if Share.canEdit model.currentUser (Just doc) then
                updateDoc_ model doc str

            else
                let
                    m =
                        "Oops, this document is being edited by " ++ (Maybe.andThen .currentEditor model.currentDocument |> Maybe.withDefault "nobody")
                in
                ( { model | messages = [ { content = m, status = MSYellow } ] }, Cmd.none )


updateDoc_ model doc str =
    let
        provisionalTitle : String
        provisionalTitle =
            Compiler.ASTTools.title model.editRecord.parsed

        ( safeContent, safeTitle ) =
            if String.left 1 provisionalTitle == "|" && doc.language == MicroLaTeXLang then
                ( String.replace "| title\n" "| title\n{untitled}\n\n" str, "{untitled}" )

            else
                ( str, provisionalTitle )

        newDocument =
            { doc | content = safeContent, title = safeTitle }

        documents =
            Util.updateDocumentInList newDocument model.documents

        publicDocuments =
            if newDocument.public then
                Util.updateDocumentInList newDocument model.publicDocuments

            else
                model.publicDocuments
    in
    ( { model
        | currentDocument = Just newDocument
        , counter = model.counter + 1
        , documents = documents
        , publicDocuments = publicDocuments
        , currentUser = Frontend.Update.addDocToCurrentUser model doc
      }
    , Cmd.batch [ sendToBackend (SaveDocument newDocument), sendToBackend (Narrowcast (Util.currentUsername model.currentUser) doc) ]
    )


changePrintingState : PrintingState -> { a | id : String } -> Cmd FrontendMsg
changePrintingState printingState doc =
    if printingState == PrintWaiting then
        Process.sleep 1000 |> Task.perform (always (FinallyDoCleanPrintArtefacts doc.id))

    else
        Cmd.none


exportToLaTeX : Document.Document -> Cmd msg
exportToLaTeX doc =
    let
        laTeXText =
            ""

        fileName =
            doc.id ++ ".lo"
    in
    Download.string fileName "application/x-latex" laTeXText


exportDoc : Document.Document -> Cmd msg
exportDoc doc =
    let
        fileName =
            doc.id ++ ".l0"
    in
    Download.string fileName "text/plain" doc.content


issueCommandIfDefined : Maybe a -> Model -> (a -> Cmd msg) -> ( Model, Cmd msg )
issueCommandIfDefined maybeSomething model cmdMsg =
    case maybeSomething of
        Nothing ->
            ( model, Cmd.none )

        Just something ->
            ( model, cmdMsg something )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        -- ADMIN
        GotShareDocumentList sharedDocList ->
            ( { model | sharedDocumentList = sharedDocList }, Cmd.none )

        GotUsersWithOnlineStatus userData ->
            ( { model | userList = userData }, Cmd.none )

        GotConnectionList connectedUsers ->
            ( { model | connectedUsers = connectedUsers }, Cmd.none )

        -- DOCUMENT
        SmartUnLockCurrentDocument ->
            Frontend.Update.lockCurrentDocumentUnconditionally { model | messages = Message.make "Transferring lock to you" MSRed }

        UnlockDocument docId ->
            Frontend.Update.lockCurrentDocumentUnconditionally { model | messages = Message.make "Transferring lock to you" MSRed }

        AcceptUserTags tagDict ->
            ( { model | tagDict = tagDict }, Cmd.none )

        AcceptPublicTags tagDict ->
            ( { model | publicTagDict = tagDict }, Cmd.none )

        ReceivedDocument documentHandling doc ->
            case documentHandling of
                StandardHandling ->
                    Frontend.Update.handleAsStandardReceivedDocument model doc

                HandleAsCheatSheet ->
                    Frontend.Update.handleReceivedDocumentAsCheatsheet model doc

        ReceivedNewDocument _ doc ->
            let
                editRecord =
                    Compiler.DifferentialParser.init doc.language doc.content

                currentMasterDocument =
                    if Frontend.Update.isMaster editRecord then
                        Just doc

                    else
                        model.currentMasterDocument
            in
            ( { model
                | editRecord = editRecord
                , title = Compiler.ASTTools.title editRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
                , documents = doc :: model.documents -- insertInListOrUpdate
                , currentDocument = Just doc
                , sourceText = doc.content
                , currentMasterDocument = currentMasterDocument
                , counter = model.counter + 1
              }
            , Cmd.batch [ Util.delay 40 (SetDocumentCurrent doc), Frontend.Cmd.setInitialEditorContent 20, View.Utility.setViewPortToTop model.popupState ]
            )

        ReceivedPublicDocuments publicDocuments ->
            case List.head publicDocuments of
                Nothing ->
                    ( { model | publicDocuments = publicDocuments }, Cmd.none )

                Just doc ->
                    let
                        cmd =
                            case model.currentUser of
                                Nothing ->
                                    if model.actualSearchKey == "" && model.url.path == "/" then
                                        Cmd.none

                                    else
                                        Util.delay 40 (SetDocumentCurrent doc)

                                Just _ ->
                                    Util.delay 40 (SetDocumentCurrent doc)
                    in
                    ( { model | publicDocuments = publicDocuments }, cmd )

        MessageReceived message ->
            let
                newMessages =
                    if List.member message.status [ Types.MSRed, Types.MSYellow, Types.MSGreen ] then
                        [ message ]

                    else
                        model.messages
            in
            ( { model | messages = newMessages }, Cmd.none )

        -- ADMIN
        SendBackupData data ->
            ( { model | messages = [ { content = "Backup data: " ++ String.fromInt (String.length data) ++ " chars", status = MSWhite } ] }, Download.string "l0-lab-demo    .json" "text/json" data )

        StatusReport items ->
            ( { model | statusReport = items }, Cmd.none )

        SetShowEditor flag ->
            ( { model | showEditor = flag }, Cmd.none )

        UserSignedUp user ->
            ( { model
                | signupState = HideSignUpForm
                , currentUser = Just user
                , maximizedIndex = MMyDocs
                , inputRealname = ""
                , inputEmail = ""
                , inputUsername = ""
                , tagSelection = TagUser
                , inputPassword = ""
                , inputPasswordAgain = ""
                , language = user.preferences.language
              }
            , Cmd.none
            )

        ReceivedDocuments documents_ ->
            let
                documents =
                    DocumentTools.sort model.sortMode documents_
            in
            case List.head documents of
                Nothing ->
                    -- ( model, sendToBackend (FetchDocumentById StandardHandling Config.notFoundDocId) )
                    ( model, Cmd.none )

                Just doc ->
                    ( { model | documents = documents, currentDocument = Just doc }, Util.delay 40 (SetDocumentCurrent doc) )

        -- CHAT (updateFromBackend)
        GotChatHistory ->
            ( model, Util.delay 400 ScrollChatToBottom )

        UserMessageReceived message ->
            ( { model | userMessage = Just message }, View.Chat.scrollChatToBottom )

        UndeliverableMessage message ->
            case message.actionOnFailureToDeliver of
                Types.FANoOp ->
                    ( model, Cmd.none )

                Types.FAUnlockCurrentDocument ->
                    Frontend.Update.lockCurrentDocumentUnconditionally { model | messages = Message.make "Transferring lock to you" MSRed }

        GotChatGroup mChatGroup ->
            case mChatGroup of
                Nothing ->
                    ( model, Cmd.none )

                Just group ->
                    let
                        cmd =
                            sendToBackend (SendChatHistory group.name)
                    in
                    ( { model | currentChatGroup = mChatGroup, inputGroup = group.name }, cmd )

        ChatMessageReceived message ->
            ( { model | chatMessages = message :: model.chatMessages }, View.Chat.scrollChatToBottom )


view : Model -> { title : String, body : List (Html.Html FrontendMsg) }
view model =
    { title = Config.appName
    , body =
        case (Element.classifyDevice { width = model.windowWidth, height = model.windowHeight }).class of
            Element.Phone ->
                [ View.Phone.view model ]

            _ ->
                [ View.Main.view model ]
    }
