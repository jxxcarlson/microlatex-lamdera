module Frontend exposing (Model, app, changePrintingState, exportDoc, exportToLaTeX, fixId_, init, issueCommandIfDefined, subscriptions, update, updateDoc, updateFromBackend, urlAction, urlIsForGuest, view)

import Browser.Events
import Browser.Navigation as Nav
import Chat
import Chat.Message
import Cmd.Extra exposing (withNoCmd)
import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Debounce
import Deque
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
import NetworkModel
import OT
import OTCommand
import Parser.Language exposing (Language(..))
import Predicate
import Process
import Render.MicroLaTeX
import Render.XMarkdown
import Share
import Task
import Time
import Types exposing (ActiveDocList(..), AppMode(..), DocLoaded(..), DocumentDeleteState(..), DocumentHandling(..), DocumentHardDeleteState(..), DocumentList(..), FrontendModel, FrontendMsg(..), MaximizedIndex(..), MessageStatus(..), PhoneMode(..), PopupState(..), PopupStatus(..), PrintingState(..), SidebarExtrasState(..), SidebarTagsState(..), SignupState(..), SortMode(..), TagSelection(..), ToBackend(..), ToFrontend(..))
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
      , messages = [ { txt = "Welcome!", status = MSWhite } ]
      , currentTime = Time.millisToPosix 0
      , zone = Time.utc
      , timeSignedIn = Time.millisToPosix 0
      , lastInteractionTime = Time.millisToPosix 0

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
      , showDocTools = False

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

      -- COLLABORATIVE EDITING
      , editCommand = { counter = -1, command = Nothing }
      , editorEvent = { counter = 0, cursor = 0, event = Nothing }
      , eventQueue = Deque.empty
      , collaborativeEditing = False
      , editorCursor = 0
      , oTDocument = OT.emptyDoc
      , myCursorPosition = { x = 0, y = 0, p = 0 }
      , networkModel = NetworkModel.init NetworkModel.emptyServerState

      -- DOCUMENT
      , includedContent = Dict.empty
      , showPublicUrl = False
      , documentDirty = False
      , seeBackups = False
      , lineNumber = 0
      , permissions = StandardHandling
      , initialText = Config.loadingText
      , documentsCreatedCounter = 0
      , sourceText = Config.loadingText
      , editRecord = Compiler.DifferentialParser.init Dict.empty L0Lang Config.loadingText
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
      , pinnedDocuments = []
      , currentDocument = Just Docs.notSignedIn
      , currentCheatsheet = Nothing
      , currentMasterDocument = Nothing
      , printingState = PrintWaiting
      , documentDeleteState = WaitingForDeleteAction
      , publicDocuments = []
      , deleteDocumentState = WaitingForDeleteAction
      , hardDeleteDocumentState = WaitingForHardDeleteAction
      , sortMode = SortAlphabetically
      , language = Config.initialLanguage
      , inputTitle = ""
      , inputReaders = ""
      , inputEditors = ""
      , inputCommand = ""
      }
    , Cmd.batch
        [ Frontend.Cmd.setupWindow
        , urlAction url.path
        , if url.path == "/" then
            sendToBackend (SearchForDocuments StandardHandling Nothing "system:startup")
            -- searchForPublicDocuments sortMode limit mUsername key model

          else
            Cmd.none
        , Task.perform AdjustTimeZone Time.here

        --- TODO: ???, sendToBackend GetCheatSheetDocument
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
                sendToBackend (SearchForDocuments StandardHandling Nothing segment)

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

        SetDocumentStatus status ->
            case model.currentDocument of
                Nothing ->
                    ( model, Cmd.none )

                Just doc ->
                    let
                        updatedDoc =
                            { doc | status = status }

                        documents =
                            Util.updateDocumentInList updatedDoc model.documents
                    in
                    ( { model | currentDocument = Just updatedDoc, documentDirty = False, documents = documents }, Frontend.Update.saveDocumentToBackend model.currentUser updatedDoc )

        FETick newTime ->
            let
                lastInteractionTimeMilliseconds =
                    model.lastInteractionTime |> Time.posixToMillis

                currentTimeMilliseconds =
                    model.currentTime |> Time.posixToMillis

                elapsedSinceLastInteractionSeconds =
                    (currentTimeMilliseconds - lastInteractionTimeMilliseconds) // 1000
            in
            -- If the lastInteractionTime has not been updated since init, do so now.
            if model.lastInteractionTime == Time.millisToPosix 0 && model.currentUser /= Nothing then
                ( { model | currentTime = newTime, lastInteractionTime = newTime }, Cmd.none )

            else if elapsedSinceLastInteractionSeconds >= Config.automaticSignoutLimit && model.currentUser /= Nothing then
                Frontend.Update.signOut { model | currentTime = newTime }

            else
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

        SetChatGroup ->
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

                        ( updatedChatMessages, cmd ) =
                            ( [], sendToBackend (SendChatHistory (String.trim model.inputGroup)) )

                        --if Just (String.trim model.inputGroup) == oldPreferences.group then
                        --    ( model.chatMessages, Cmd.none )
                        --
                        --else
                        --    ( [], sendToBackend (SendChatHistory (String.trim model.inputGroup)) )
                    in
                    ( { model | currentUser = Just revisedUser, chatMessages = updatedChatMessages }, Cmd.batch [ cmd, sendToBackend (UpdateUserWith revisedUser) ] )

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

        TogglePublicUrl ->
            ( { model | showPublicUrl = not model.showPublicUrl }, Cmd.none )

        -- CHAT
        ToggleChat ->
            ( { model | chatVisible = not model.chatVisible, chatMessages = [] }, Cmd.batch [ Util.delay 200 ScrollChatToBottom, sendToBackend (SendChatHistory model.inputGroup) ] )

        ToggleDocTools ->
            ( { model | showDocTools = not model.showDocTools }, Cmd.none )

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

        -- USER MESSAGES
        DismissUserMessage ->
            ( { model | userMessage = Nothing }, Cmd.none )

        SendUserMessage message ->
            ( { model | userMessage = Nothing }, sendToBackend (DeliverUserMessage message) )

        OpenSharedDocumentList ->
            ( model
            , sendToBackend (GetSharedDocuments (model.currentUser |> Maybe.map .username |> Maybe.withDefault "(anon)"))
            )

        -- USER
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
            Frontend.Update.signIn model

        SignOut ->
            Frontend.Update.signOut model

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

        ToggleManuals ->
            case model.popupState of
                NoPopup ->
                    ( { model | popupState = ManualsPopup }, sendToBackend (FetchDocumentById HandleAsCheatSheet Config.manualsId) )

                _ ->
                    ( { model | popupState = NoPopup }, Cmd.none )

        SelectList list ->
            let
                cmd =
                    if list == SharedDocumentList then
                        sendToBackend (GetSharedDocuments (model.currentUser |> Maybe.map .username |> Maybe.withDefault "(anon)"))

                    else if list == PinnedDocs then
                        sendToBackend (SearchForDocuments PinnedDocumentList (model.currentUser |> Maybe.map .username) "pin")

                    else
                        Cmd.none
            in
            ( { model | lastInteractionTime = model.currentTime, documentList = list }, cmd )

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
            ( { model | messages = [ { txt = "Selection: " ++ str, status = MSWhite } ] }, Cmd.none )

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
                    ( { model | messages = [ { txt = "No document to open in editor", status = MSWhite } ] }, Cmd.none )

                Just doc ->
                    Frontend.Update.openEditor doc model

        Help docId ->
            ( model, sendToBackend (SearchForDocumentsWithAuthorAndKey docId) )

        -- SHARE
        Narrow username document ->
            ( model, sendToBackend (Narrowcast (Util.currentUserId model.currentUser) username document) )

        -- DOCUMENT
        ChangeLanguage ->
            case model.currentDocument of
                Nothing ->
                    ( model, Cmd.none )

                Just doc ->
                    let
                        newDocument =
                            { doc | language = model.language }
                    in
                    ( model
                    , sendToBackend (SaveDocument model.currentUser newDocument)
                    )
                        |> (\( m, c ) -> ( Frontend.Update.postProcessDocument newDocument m, c ))

        ToggleBackupVisibility ->
            ( { model | seeBackups = not model.seeBackups }, Cmd.none )

        MakeBackup ->
            case ( model.currentUser, model.currentDocument ) of
                ( Nothing, _ ) ->
                    ( model, Cmd.none )

                ( _, Nothing ) ->
                    ( model, Cmd.none )

                ( Just user, Just doc ) ->
                    if Just user.username == doc.author then
                        let
                            newDocument =
                                Document.makeBackup doc
                        in
                        ( model, sendToBackend (InsertDocument user newDocument) )

                    else
                        ( model, Cmd.none )

        InputReaders str ->
            ( { model | inputReaders = str }, Cmd.none )

        InputEditors str ->
            ( { model | inputEditors = str }, Cmd.none )

        ShareDocument ->
            Share.shareDocument model

        DoShare ->
            Share.doShare model

        ToggleCollaborativeEditing ->
            case model.currentDocument of
                Nothing ->
                    ( model, Cmd.none )

                Just doc ->
                    case model.collaborativeEditing of
                        False ->
                            ( model, sendToBackend (InitializeNetworkModelsWithDocument doc) )

                        True ->
                            ( model, sendToBackend (ResetNetworkModelForDocument doc) )

        GetPinnedDocuments ->
            ( { model | documentList = StandardList }, sendToBackend (SearchForDocuments PinnedDocumentList (model.currentUser |> Maybe.map .username) "pin") )

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
            -- This is the only route to function updateDoc, updateDoc_
            if Predicate.documentIsMineOrIAmAnEditor model.currentDocument model.currentUser then
                updateDoc model str

            else
                ( model, Cmd.none )

        Search ->
            ( { model
                | actualSearchKey = model.inputSearchKey
                , documentList = StandardList
                , currentMasterDocument = Nothing
              }
            , sendToBackend (SearchForDocuments StandardHandling (model.currentUser |> Maybe.map .username) model.inputSearchKey)
            )

        SearchText ->
            Frontend.Update.searchText model

        InputText { position, source } ->
            Frontend.Update.inputText model { position = position, source = source }

        InputCommand str ->
            ( { model | inputCommand = str }, Cmd.none )

        InputCursor { position, source } ->
            Frontend.Update.inputCursor { position = position, source = source } model

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

        SetHardDeleteDocumentState s ->
            ( { model | hardDeleteDocumentState = s }, Cmd.none )

        SoftDeleteDocument ->
            Frontend.Update.softDeleteDocument model

        HardDeleteDocument ->
            Frontend.Update.hardDeleteDocument model

        SetPublicDocumentAsCurrentById id ->
            Frontend.Update.setPublicDocumentAsCurrentById model id

        SetDocumentCurrent document ->
            case model.currentDocument of
                Nothing ->
                    Frontend.Update.setDocumentAsCurrent Cmd.none model document StandardHandling

                Just currentDocument ->
                    Frontend.Update.handleCurrentDocumentChange model currentDocument document

        -- Handles button clicks
        SetDocumentAsCurrent handling document ->
            case model.currentDocument of
                Nothing ->
                    Frontend.Update.setDocumentAsCurrent Cmd.none model document handling

                Just currentDocument ->
                    Frontend.Update.handleCurrentDocumentChange model currentDocument document

        SetDocumentCurrentViaId id ->
            case Document.documentFromListViaId id model.documents of
                Nothing ->
                    ( model, Cmd.none )

                Just doc ->
                    ( Frontend.Update.postProcessDocument doc model, Cmd.none )

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

        RunCommand ->
            ( { model | counter = model.counter + 1, editCommand = { counter = model.counter, command = OTCommand.parseCommand model.inputCommand } }, Cmd.none )

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
            case doc.status of
                Document.DSSoftDelete ->
                    ( model, Cmd.none )

                Document.DSReadOnly ->
                    ( { model | messages = [ { txt = "Document is read-only (can't save edits)", status = MSRed } ] }, Cmd.none )

                Document.DSCanEdit ->
                    -- if Share.canEdit model.currentUser (Just doc) then
                    -- if View.Utility.canSaveStrict model.currentUser doc then
                    if Document.numberOfEditors (Just doc) < 2 && doc.handling == Document.DHStandard then
                        updateDoc_ doc str model

                    else
                        let
                            m =
                                if doc.handling == Document.DHStandard then
                                    "Oops, this document is being edited by other people"
                                    -- TODO: this is nonsense

                                else
                                    "Oops, this is a backup or version document -- no edits"
                        in
                        ( { model | messages = [ { txt = m, status = MSYellow } ] }, Cmd.none )


updateDoc_ : Document.Document -> String -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
updateDoc_ doc str model =
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
        , documentDirty = False
        , publicDocuments = publicDocuments
        , currentUser = Frontend.Update.addDocToCurrentUser model doc
      }
    , Cmd.batch [ Frontend.Update.saveDocumentToBackend model.currentUser newDocument ]
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

        -- COLLABORATIVE EDITING
        InitializeNetworkModel networkModel ->
            ( { model | collaborativeEditing = True, networkModel = networkModel, editCommand = { counter = model.counter, command = Just (OTCommand.CSkip 0 0) } }, Cmd.none )

        ResetNetworkModel networkModel document ->
            ( { model
                | collaborativeEditing = False
                , networkModel = networkModel
                , currentDocument = Just document
                , documents = Util.updateDocumentInList document model.documents
                , showEditor = False
              }
            , Cmd.none
            )

        -- DOCUMENT
        GotIncludedData doc listOfData ->
            let
                includedContent =
                    List.foldl (\( tag, content ) acc -> Dict.insert tag content acc) model.includedContent listOfData

                updateEditRecord : Dict.Dict String String -> Document.Document -> FrontendModel -> FrontendModel
                updateEditRecord inclusionData doc_ model_ =
                    Frontend.Update.updateEditRecord inclusionData doc_ model_
            in
            ( { model | includedContent = includedContent } |> (\m -> updateEditRecord includedContent doc m)
            , Cmd.none
            )

        AcceptUserTags tagDict ->
            ( { model | tagDict = tagDict }, Cmd.none )

        AcceptPublicTags tagDict ->
            ( { model | publicTagDict = tagDict }, Cmd.none )

        -- COLLABORATIVE EDITING
        ProcessEvent event ->
            let
                networkModel =
                    NetworkModel.updateFromBackend NetworkModel.applyEvent event model.networkModel

                doc : OT.Document
                doc =
                    NetworkModel.getLocalDocument networkModel

                newEditRecord : Compiler.DifferentialParser.EditRecord
                newEditRecord =
                    Compiler.DifferentialParser.init model.includedContent model.language doc.content

                cursor =
                    model.networkModel.serverState.document.cursor

                --editorEvent =
                --    if Util.currentUserId model.currentUser /= event.userId then
                --        Just event |> Debug.log "!!! Add Event"
                --
                --    else
                --        model.editorEvent.event
                editCommand_ =
                    { counter = model.counter, command = event |> OTCommand.toCommand cursor }

                editCommand =
                    if Util.currentUserId model.currentUser /= event.userId then
                        editCommand_

                    else
                        { counter = model.counter, command = Nothing }
            in
            ( { model
                | editCommand = editCommand

                -- editorEvent = { counter = model.counter, cursor = cursor, event = editorEvent }
                -- TODO!!
                -- ,  eventQueue = Deque.pushFront event model.eventQueue
                , networkModel = networkModel
                , editRecord = newEditRecord
              }
            , Cmd.none
            )

        ReceivedDocument documentHandling doc ->
            case documentHandling of
                StandardHandling ->
                    Frontend.Update.handleAsStandardReceivedDocument model doc

                DelayedHandling ->
                    Frontend.Update.handleAsReceivedDocumentWithDelay model doc

                PinnedDocumentList ->
                    Frontend.Update.handleAsStandardReceivedDocument model doc

                HandleAsCheatSheet ->
                    Frontend.Update.handleReceivedDocumentAsCheatsheet model doc

        ReceivedNewDocument _ doc ->
            let
                editRecord =
                    Compiler.DifferentialParser.init model.includedContent doc.language doc.content

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
            ( { model | messages = [ { txt = "Backup data: " ++ String.fromInt (String.length data) ++ " chars", status = MSWhite } ] }, Download.string "l0-lab-demo    .json" "text/json" data )

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
                , timeSignedIn = model.currentTime
              }
            , Cmd.none
            )

        ReceivedDocuments documentHandling documents_ ->
            let
                documents =
                    DocumentTools.sort model.sortMode documents_
            in
            case List.head documents of
                Nothing ->
                    -- ( model, sendToBackend (FetchDocumentById DelayedHandling Config.notFoundDocId) )
                    ( model, Cmd.none )

                Just doc ->
                    case documentHandling of
                        PinnedDocumentList ->
                            ( { model | pinnedDocuments = List.map Document.toDocInfo documents, currentDocument = Just doc }
                            , Cmd.none
                              -- TODO: ??, Cmd.batch [ Util.delay 40 (SetDocumentCurrent doc) ]
                            )

                        _ ->
                            ( { model | documents = documents, currentDocument = Just doc } |> Frontend.Update.postProcessDocument doc
                            , Cmd.none
                            )

        -- USER MESSAGES
        UserMessageReceived message ->
            ( { model | userMessage = Just message }, View.Chat.scrollChatToBottom )

        UndeliverableMessage message ->
            ( model, Cmd.none )

        --case message.actionOnFailureToDeliver of
        --    Types.FANoOp ->
        --        ( model, Cmd.none )
        --
        --    Types.FAUnlockCurrentDocument ->
        --        Frontend.Update.lockCurrentDocumentUnconditionally { model | messages = Message.make "Transferring lock to you" MSRed }
        -- CHAT (updateFromBackend)
        GotChatHistory history ->
            ( { model | chatMessages = history }, Util.delay 400 ScrollChatToBottom )

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
            ( { model | chatMessages = Chat.consolidateOne message model.chatMessages }, View.Chat.scrollChatToBottom )


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
