module Frontend exposing (Model, app, changePrintingState, exportDoc, exportToLaTeX, fixId_, init, issueCommandIfDefined, subscriptions, update, updateFromBackend, view)

import Chat
import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OTCommand as OTCommand
import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Debounce
import Deque
import Dict
import Docs
import Document
import Duration
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Command exposing (Command, FrontendOnly)
import Effect.File.Download
import Effect.Lamdera
import Effect.Process
import Effect.Subscription as Subscription
import Effect.Task
import Effect.Time
import Element
import Env
import Frontend.AppState
import Frontend.Authentication
import Frontend.Chat
import Frontend.Cmd
import Frontend.Collaboration
import Frontend.Document
import Frontend.DocumentList
import Frontend.Documentation
import Frontend.Editor
import Frontend.Export
import Frontend.Message
import Frontend.Navigation
import Frontend.PDF as PDF
import Frontend.Scheduler
import Frontend.Search
import Frontend.Update
import Frontend.UpdateDocument
import Frontend.Widget
import Html
import IncludeFiles
import Keyboard
import Lamdera
import Markup
import Parser.Language exposing (Language(..))
import Predicate
import Share
import Types
    exposing
        ( ActiveDocList(..)
        , AppMode(..)
        , DocLoaded(..)
        , DocumentDeleteState(..)
        , DocumentHandling(..)
        , DocumentHardDeleteState(..)
        , DocumentList(..)
        , FrontendModel
        , FrontendMsg(..)
        , MaximizedIndex(..)
        , MessageStatus(..)
        , PhoneMode(..)
        , PopupState(..)
        , PopupStatus(..)
        , PrintingState(..)
        , SidebarExtrasState(..)
        , SidebarTagsState(..)
        , SignupState(..)
        , SortMode(..)
        , TagSelection(..)
        , ToBackend(..)
        , ToFrontend(..)
        )
import Url
import User
import Util
import View.Chat
import View.Main
import View.Phone
import View.Utility


type alias Model =
    FrontendModel


app =
    Effect.Lamdera.frontend
        Lamdera.sendToBackend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        }


subscriptions _ =
    Subscription.batch
        [ Effect.Browser.Events.onResize (\w h -> GotNewWindowDimensions w h)
        , Effect.Time.every (Config.frontendTickSeconds * 1000 |> Duration.milliseconds) FETick
        , Subscription.map KeyMsg Keyboard.subscriptions
        ]



-- INIT


init : Url.Url -> Effect.Browser.Navigation.Key -> ( Model, Command FrontendOnly ToBackend FrontendMsg )
init url key =
    ( { key = key
      , url = url
      , messages = [ { txt = "Welcome!", status = MSWhite } ]
      , currentTime = Effect.Time.millisToPosix 0
      , zone = Effect.Time.utc
      , timeSignedIn = Effect.Time.millisToPosix 0
      , lastInteractionTime = Effect.Time.millisToPosix 0
      , timer = 0
      , showSignInTimer = False

      -- ADMIN
      , statusReport = []
      , inputSpecial = ""
      , userList = []
      , connectedUsers = []
      , sharedDocumentList = []

      -- USER
      , userMessage = Nothing
      , currentUser = Nothing
      , clientIds = []
      , inputUsername = ""
      , inputSignupUsername = ""
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
      , indexDisplay = Types.IDDocuments
      , appMode = UserMode
      , showTOC = True
      , experimentalMode = False
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
      , selectedSlug = Nothing
      , searchCount = 0
      , searchSourceText = ""
      , syncRequestIndex = 0

      -- COLLABORATIVE EDITING
      , editCommand = { counter = -1, command = OTCommand.CNoOp }
      , editorEvent = { counter = 0, cursor = 0, event = Nothing }
      , eventQueue = Deque.empty
      , collaborativeEditing = False
      , editorCursor = 0
      , myCursorPosition = { x = 0, y = 0, p = 0 }
      , networkModel = NetworkModel.init (NetworkModel.initialServerState "foo" "bar" "baz")
      , oTDocument = { docId = "!---!", cursor = 0, content = "" }

      -- SHARED EDITING
      , activeEditor = Nothing

      -- DOCUMENT
      , inputFolderName = ""
      , inputFolderTag = ""
      , allowOpenFolder = True
      , includedContent = Dict.empty
      , showPublicUrl = False
      , documentDirty = False
      , hideBackups = True
      , lineNumber = 0
      , permissions = StandardHandling
      , initialText = Config.initialText
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
      , currentManual = Nothing
      , currentMasterDocument = Nothing
      , printingState = PrintWaiting
      , documentDeleteState = WaitingForDeleteAction
      , publicDocuments = []
      , hideDeletedDocuments = True
      , deleteDocumentState = WaitingForDeleteAction
      , hardDeleteDocumentState = WaitingForHardDeleteAction
      , sortMode = SortByMostRecent
      , language = Config.initialLanguage
      , inputTitle = ""
      , inputReaders = ""
      , inputEditors = ""
      , inputCommand = ""
      }
    , Effect.Command.batch
        [ Frontend.Cmd.setupWindow
        , Frontend.Navigation.urlAction url.path
        , if url.path == "/" then
            Effect.Lamdera.sendToBackend (SearchForDocuments StandardHandling Nothing "jxxcarlson:system-home")
            -- searchForPublicDocuments sortMode limit mUsername key model

          else
            Effect.Command.none
        , Effect.Task.perform AdjustTimeZone Effect.Time.here
        , case Env.mode of
            Env.Development ->
                Effect.Lamdera.sendToBackend ClearConnectionDictBE

            Env.Production ->
                Effect.Command.none

        --- TODO: ???, sendToBackend GetCheatSheetDocument
        ]
    )


update : FrontendMsg -> Model -> ( Model, Command FrontendOnly ToBackend FrontendMsg )
update msg model =
    case msg of
        ApplyEdits ->
            let
                newNetworkModel =
                    NetworkModel.applyLocalEvents model.networkModel
            in
            ( { model | networkModel = newNetworkModel }, Effect.Command.none )

        FENoOp ->
            ( model, Effect.Command.none )

        SetDocumentStatus status ->
            Frontend.UpdateDocument.setDocumentStatus model status

        FETick newTime ->
            Frontend.Scheduler.schedule model newTime

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }, Effect.Command.none )

        GotTime _ ->
            ( model, Effect.Command.none )

        KeyMsg keyMsg ->
            Frontend.Update.updateKeys model keyMsg

        UrlClicked urlRequest ->
            Frontend.Update.handleUrlRequest model urlRequest

        UrlChanged url ->
            Frontend.Navigation.respondToUrlChange model url

        -- CHAT (update)
        AskToClearChatHistory ->
            ( model, Effect.Lamdera.sendToBackend (ClearChatHistory model.inputGroup) )

        SetChatGroup ->
            Frontend.Chat.setGroup model

        GetChatHistory ->
            ( model, Effect.Command.batch [ Effect.Lamdera.sendToBackend (SendChatHistory model.inputGroup) ] )

        ScrollChatToBottom ->
            ( model, View.Chat.scrollChatToBottom )

        CreateChatGroup ->
            Frontend.Chat.createGroup model

        SetChatDisplay option ->
            ( { model | chatDisplay = option }, Effect.Command.none )

        InputFolderName str ->
            ( { model | inputFolderName = str }, Effect.Command.none )

        InputFolderTag str ->
            ( { model | inputFolderTag = str }, Effect.Command.none )

        InputGroupName str ->
            ( { model | inputGroupName = str }, Effect.Command.none )

        InputGroupAssistant str ->
            ( { model | inputGroupAssistant = str }, Effect.Command.none )

        InputGroupMembers str ->
            ( { model | inputGroupMembers = str }, Effect.Command.none )

        InputChoseGroup str ->
            ( { model | inputGroup = str }, Effect.Lamdera.sendToBackend (GetChatGroup str) )

        ToggleTOC ->
            ( { model | showTOC = not model.showTOC }, Effect.Command.none )

        TogglePublicUrl ->
            ( { model | showPublicUrl = not model.showPublicUrl }, Effect.Command.none )

        ToggleExperimentalMode ->
            ( { model | experimentalMode = not model.experimentalMode }, Effect.Command.none )

        -- CHAT
        ToggleChat ->
            ( { model | chatVisible = not model.chatVisible, chatMessages = [] }, Effect.Command.batch [ Util.delay 200 ScrollChatToBottom, Effect.Lamdera.sendToBackend (SendChatHistory model.inputGroup) ] )

        ToggleDocTools ->
            ( { model | showDocTools = not model.showDocTools }, Effect.Command.none )

        MessageFieldChanged str ->
            ( { model | chatMessageFieldContent = str }, Effect.Command.none )

        -- User has hit the Send button
        MessageSubmitted ->
            Frontend.Message.submitted model

        -- USER MESSAGES
        DismissUserMessage ->
            ( { model | userMessage = Nothing }, Effect.Command.none )

        SendUserMessage message ->
            ( { model | userMessage = Nothing }, Effect.Lamdera.sendToBackend (DeliverUserMessage message) )

        OpenSharedDocumentList ->
            ( model
            , Effect.Lamdera.sendToBackend (GetSharedDocuments (model.currentUser |> Maybe.map .username |> Maybe.withDefault "(anon)"))
            )

        -- USER
        SetSignupState state ->
            Frontend.Authentication.setSignupState model state

        SignUp ->
            Frontend.Update.signUp model

        SignIn ->
            Frontend.Update.signIn model

        SignOut ->
            Frontend.Update.signOut model

        -- ADMIN
        ClearConnectionDict ->
            ( model, Effect.Lamdera.sendToBackend ClearConnectionDictBE )

        GoGetUserList ->
            ( model, Effect.Lamdera.sendToBackend GetUserList )

        InputSpecial str ->
            ( { model | inputSpecial = str }, Effect.Command.none )

        RunSpecial ->
            Frontend.Update.runSpecial model

        InputUsername str ->
            ( { model | inputUsername = str }, Effect.Command.none )

        InputSignupUsername str ->
            ( { model | inputSignupUsername = str }, Effect.Command.none )

        InputPassword str ->
            ( { model | inputPassword = str }, Effect.Command.none )

        ClearPassword ->
            ( { model | inputPassword = "" }, Effect.Command.none )

        InputPasswordAgain str ->
            ( { model | inputPasswordAgain = str }, Effect.Command.none )

        InputRealname str ->
            ( { model | inputRealname = str }, Effect.Command.none )

        InputEmail str ->
            ( { model | inputEmail = str }, Effect.Command.none )

        -- UI
        ToggleGuides ->
            Frontend.Documentation.toggleGuides model

        ToggleManuals manualType ->
            Frontend.Documentation.toggleManuals model manualType

        SelectList list ->
            Frontend.DocumentList.selectDocumentList model list

        ChangePopup popupState ->
            ( { model | popupState = popupState }, Effect.Command.none )

        ToggleIndexSize ->
            Frontend.DocumentList.toggleIndexSize model

        CloseCollectionIndex ->
            Frontend.DocumentList.closeCollectionIndex model

        ToggleActiveDocList ->
            Frontend.DocumentList.toggleActiveDocumentList model

        Home ->
            ( model, Effect.Lamdera.sendToBackend (GetDocumentById Types.StandardHandling Config.welcomeDocId) )

        ShowTOCInPhone ->
            ( { model | phoneMode = PMShowDocumentList }, Effect.Command.none )

        SetDocumentInPhoneAsCurrent permissions doc ->
            Frontend.Update.setDocumentInPhoneAsCurrent model doc permissions

        SetAppMode appMode ->
            Frontend.AppState.set model appMode

        GotNewWindowDimensions w h ->
            ( { model | windowWidth = w, windowHeight = h }, Effect.Command.none )

        GotViewport vp ->
            Frontend.Update.updateWithViewport vp model

        SetViewPortForElement result ->
            Frontend.Update.setViewportForElement model result

        InputSearchSource str ->
            ( { model | searchSourceText = str, foundIdIndex = 0 }, Effect.Command.none )

        GetSelection str ->
            ( { model | messages = [ { txt = "Selection: " ++ str, status = MSWhite } ] }, Effect.Command.none )

        -- SYNC
        SelectedText str ->
            Frontend.Update.firstSyncLR model str

        SendSyncLR ->
            ( { model | syncRequestIndex = model.syncRequestIndex + 1 }, Effect.Command.none )

        SyncLR ->
            Frontend.Update.syncLR model

        StartSync ->
            ( { model | doSync = not model.doSync }, Effect.Command.none )

        NextSync ->
            Frontend.Update.nextSyncLR model

        ChangePopupStatus status ->
            ( { model | popupStatus = status }, Effect.Command.none )

        NoOpFrontendMsg ->
            ( model, Effect.Command.none )

        CloseEditor ->
            Frontend.Update.closeEditor model

        OpenEditor ->
            Frontend.Editor.open model

        Help docId ->
            ( model, Effect.Lamdera.sendToBackend (SearchForDocumentsWithAuthorAndKey docId) )

        -- SHARE
        Narrow username document ->
            ( model, Effect.Lamdera.sendToBackend (Narrowcast (User.currentUserId model.currentUser) username document) )

        -- DOCUMENT
        ToggleAllowOpenFolder ->
            ( { model | allowOpenFolder = not model.allowOpenFolder }, Effect.Command.none )

        ChangeLanguage ->
            Frontend.Document.changeLanguage model

        ToggleBackupVisibility ->
            ( { model | hideBackups = not model.hideBackups }, Effect.Command.none )

        MakeBackup ->
            Frontend.Document.makeBackup model

        InputReaders str ->
            ( { model | inputReaders = str }, Effect.Command.none )

        InputEditors str ->
            ( { model | inputEditors = str }, Effect.Command.none )

        ShareDocument ->
            Share.shareDocument model

        DoShare ->
            Share.doShare model

        ToggleCollaborativeEditing ->
            Frontend.Collaboration.toggle model

        GetPinnedDocuments ->
            ( { model | documentList = StandardList }, Effect.Lamdera.sendToBackend (SearchForDocuments PinnedDocumentList model.currentUser "pin") )

        -- TAGS
        GetUserTags ->
            ( { model | tagSelection = TagUser }, Effect.Command.none )

        GetPublicTags ->
            ( { model | tagSelection = TagPublic }, Effect.Command.none )

        ToggleExtrasSidebar ->
            Frontend.Widget.toggleExtrasSidebar model

        ToggleTagsSidebar ->
            Frontend.Widget.toggleSidebar model

        SetLanguage dismiss lang ->
            Frontend.Update.setLanguage dismiss lang model

        SetUserLanguage lang ->
            Frontend.Update.setUserLanguage lang model

        Render msg_ ->
            Frontend.Update.render model msg_

        Fetch id ->
            ( model, Effect.Lamdera.sendToBackend (FetchDocumentById StandardHandling id) )

        DebounceMsg msg_ ->
            Frontend.Update.debounceMsg model msg_

        Saved str ->
            Frontend.Document.updateDoc model str

        GetFolders ->
            ( { model | indexDisplay = Types.IDFolders }, Effect.Lamdera.sendToBackend (SearchForDocuments StandardHandling model.currentUser ":folder") )

        GetDocs ->
            ( { model | indexDisplay = Types.IDDocuments }, Effect.Lamdera.sendToBackend (SearchForDocuments StandardHandling model.currentUser "") )

        Search ->
            Frontend.Search.search model

        SearchText ->
            Frontend.Update.searchText model

        InputText { position, source } ->
            Frontend.Update.inputText model { position = position, source = source }

        InputCommand str ->
            ( { model | inputCommand = str }, Effect.Command.none )

        InputCursor { position, source } ->
            Frontend.Update.inputCursor { position = position, source = source } model

        InputTitle str ->
            Frontend.Update.inputTitle model str

        SetInitialEditorContent ->
            Frontend.Update.setInitialEditorContent model

        InputAuthorId str ->
            ( { model | authorId = str }, Effect.Command.none )

        AskForDocumentById documentHandling id ->
            ( model, Effect.Lamdera.sendToBackend (GetDocumentById documentHandling id) )

        AskForDocumentByAuthorId ->
            ( model, Effect.Lamdera.sendToBackend (SearchForDocumentsWithAuthorAndKey model.authorId) )

        InputSearchKey str ->
            ( { model | inputSearchKey = str }, Effect.Command.none )

        InputSearchTagsKey str ->
            ( { model | inputSearchTagsKey = str }, Effect.Command.none )

        CreateFolder ->
            Frontend.Update.newFolder model

        NewDocument ->
            Frontend.Update.newDocument model

        ChangeSlug ->
            Frontend.Update.changeSlug model

        SetDeleteDocumentState s ->
            ( { model | deleteDocumentState = s }, Effect.Command.none )

        SetHardDeleteDocumentState s ->
            ( { model | hardDeleteDocumentState = s }, Effect.Command.none )

        SoftDeleteDocument ->
            Frontend.Update.softDeleteDocument model

        HardDeleteAll ->
            Frontend.Document.hardDeleteAll model

        Undelete ->
            Frontend.Update.undeleteDocument model

        HardDeleteDocument ->
            Frontend.Update.hardDeleteDocument model

        SetPublicDocumentAsCurrentById id ->
            Frontend.Update.setPublicDocumentAsCurrentById model id

        -- Handles button clicks
        SetDocumentAsCurrent handling document ->
            Frontend.Document.setDocumentAsCurrent model handling document

        SetDocumentCurrentViaId id ->
            Frontend.Document.setDocumentAsCurrentViaId model id

        SetPublic doc public ->
            Frontend.Update.setPublic model doc public

        SetSortMode sortMode ->
            ( { model | sortMode = sortMode }, Effect.Command.none )

        -- Export
        ExportToMarkdown ->
            Frontend.Update.exportToMarkdown model

        ExportToLaTeX ->
            Frontend.Update.exportToLaTeX model

        ExportToRawLaTeX ->
            Frontend.Update.exportToRawLaTeX model

        ExportTo lang ->
            Frontend.Export.to model lang

        Export ->
            issueCommandIfDefined model.currentDocument model exportDoc

        RunNetworkModelCommand ->
            ( { model | counter = model.counter + 1, editCommand = { counter = model.counter, command = OTCommand.parseCommand model.inputCommand } }, Effect.Command.none )

        PrintToPDF ->
            PDF.print model

        GotPdfLink result ->
            PDF.gotLink model result

        ChangePrintingState printingState ->
            -- TODO: review this
            issueCommandIfDefined model.currentDocument { model | printingState = printingState } (changePrintingState printingState)

        FinallyDoCleanPrintArtefacts _ ->
            ( model, Effect.Command.none )


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



--else
--    let
--        m =
--            if doc.handling == Document.DHStandard then
--                "Oops, this document is being edited by other people"
--                -- TODO: this is nonsense
--
--            else
--                "Oops, this is a backup or version document -- no edits"
--    in
--    -- ( { model | messages = [ { txt = m, status = MSYellow } ] }, sendToBackend (Narrowcast (User.currentUserId model.currentUser) (User.currentUsername model.currentUser) doc) )
--    -- ( { model | messages = [ { txt = m, status = MSYellow } ] }, Cmd.none )
--    -- ( { model | messages = [ { txt = m, status = MSYellow } ] }, sendToBackend (NarrowcastExceptToSender (User.currentUserId model.currentUser) (User.currentUsername model.currentUser) doc) )
--    ( { model | messages = [ { txt = m, status = MSYellow } ] }, Cmd.none )


changePrintingState : PrintingState -> { a | id : String } -> Command FrontendOnly ToBackend FrontendMsg
changePrintingState printingState doc =
    if printingState == PrintWaiting then
        Effect.Process.sleep (Duration.milliseconds 1000) |> Effect.Task.perform (always (FinallyDoCleanPrintArtefacts doc.id))

    else
        Effect.Command.none


exportToLaTeX : Document.Document -> Command FrontendOnly ToBackend msg
exportToLaTeX doc =
    let
        laTeXText =
            ""

        fileName =
            doc.id ++ ".lo"
    in
    Effect.File.Download.string fileName "application/x-latex" laTeXText


exportDoc : Document.Document -> Command FrontendOnly ToBackend msg
exportDoc doc =
    let
        fileName =
            doc.id ++ ".l0"
    in
    Effect.File.Download.string fileName "text/plain" doc.content


issueCommandIfDefined : Maybe a -> Model -> (a -> Command FrontendOnly ToBackend msg) -> ( Model, Command FrontendOnly ToBackend msg )
issueCommandIfDefined maybeSomething model cmdMsg =
    case maybeSomething of
        Nothing ->
            ( model, Effect.Command.none )

        Just something ->
            ( model, cmdMsg something )


updateFromBackend : ToFrontend -> Model -> ( Model, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend msg model =
    case msg of
        -- ADMIN
        GotShareDocumentList sharedDocList ->
            ( { model | sharedDocumentList = sharedDocList }, Effect.Command.none )

        GotUsersWithOnlineStatus userData ->
            ( { model | userList = userData }, Effect.Command.none )

        GotConnectionList connectedUsers ->
            ( { model | connectedUsers = connectedUsers }, Effect.Command.none )

        -- COLLABORATIVE EDITING
        InitializeNetworkModel networkModel ->
            Frontend.Collaboration.initializeNetworkModel model networkModel

        ResetNetworkModel networkModel document ->
            Frontend.Collaboration.resetNetworkModel model networkModel document

        -- DOCUMENT
        GotIncludedData doc listOfData ->
            Frontend.Document.gotIncludedUserData model doc listOfData

        AcceptUserTags tagDict ->
            ( { model | tagDict = tagDict }, Effect.Command.none )

        AcceptPublicTags tagDict ->
            ( { model | publicTagDict = tagDict }, Effect.Command.none )

        -- COLLABORATIVE EDITING
        ProcessEvent event ->
            Frontend.Collaboration.processEvent model event

        ReceivedDocument documentHandling doc ->
            case documentHandling of
                StandardHandling ->
                    Frontend.Update.handleAsStandardReceivedDocument model doc

                KeepMasterDocument masterDoc ->
                    Frontend.Update.handleKeepingMasterDocument model masterDoc doc

                HandleSharedDocument username ->
                    Frontend.Update.handleSharedDocument model username doc

                PinnedDocumentList ->
                    Frontend.Update.handleAsStandardReceivedDocument model doc

                HandleAsManual ->
                    Frontend.Update.handleReceivedDocumentAsManual model doc

        ReceivedNewDocument _ doc ->
            let
                editRecord =
                    Compiler.DifferentialParser.init model.includedContent doc.language doc.content

                currentMasterDocument =
                    if Predicate.isMaster editRecord then
                        Just doc

                    else
                        model.currentMasterDocument
            in
            ( { model
                | editRecord = editRecord
                , title = Compiler.ASTTools.title editRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
                , currentDocument = Just doc
                , documents = doc :: model.documents
                , sourceText = doc.content
                , currentMasterDocument = currentMasterDocument
                , counter = model.counter + 1
              }
            , Effect.Command.batch [ Util.delay 40 (SetDocumentAsCurrent StandardHandling doc), Frontend.Cmd.setInitialEditorContent 20, View.Utility.setViewPortToTop model.popupState ]
            )

        ReceivedPublicDocuments publicDocuments ->
            case List.head publicDocuments of
                Nothing ->
                    ( { model | publicDocuments = publicDocuments }, Effect.Command.none )

                Just doc ->
                    let
                        ( currentMasterDocument, newEditRecord, getFirstDocumentCommand ) =
                            Frontend.Update.prepareMasterDocument model doc

                        -- TODO: fix this
                        filesToInclude =
                            IncludeFiles.getData doc.content

                        loadCmd =
                            case List.isEmpty filesToInclude of
                                True ->
                                    Effect.Command.none

                                False ->
                                    Effect.Lamdera.sendToBackend (GetIncludedFiles doc filesToInclude)
                    in
                    ( { model
                        | currentMasterDocument = currentMasterDocument
                        , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
                        , currentDocument = Just doc
                        , editRecord = newEditRecord
                        , publicDocuments = publicDocuments
                      }
                    , Effect.Command.batch [ loadCmd, getFirstDocumentCommand ]
                    )

        ReceivedDocuments documentHandling documents ->
            case List.head documents of
                Nothing ->
                    -- ( model, sendToBackend (FetchDocumentById DelayedHandling Config.notFoundDocId) )
                    ( model, Effect.Command.none )

                Just doc ->
                    case documentHandling of
                        PinnedDocumentList ->
                            ( { model | pinnedDocuments = List.map Document.toDocInfo documents, currentDocument = Just doc }
                            , Effect.Command.none
                            )

                        _ ->
                            ( { model | documents = documents, currentDocument = Just doc } |> Frontend.Update.postProcessDocument doc
                            , Effect.Command.none
                            )

        MessageReceived message ->
            let
                newMessages =
                    if List.member message.status [ Types.MSRed, Types.MSYellow, Types.MSGreen ] then
                        [ message ]

                    else
                        model.messages
            in
            if message.txt == "Sorry, password and username don't match" then
                ( { model | inputPassword = "", messages = newMessages }, Effect.Command.none )

            else
                ( { model | messages = newMessages }, Effect.Command.none )

        -- ADMIN
        SendBackupData data ->
            ( { model | messages = [ { txt = "Backup data: " ++ String.fromInt (String.length data) ++ " chars", status = MSWhite } ] }, Effect.File.Download.string "l0-lab-demo    .json" "text/json" data )

        StatusReport items ->
            ( { model | statusReport = items }, Effect.Command.none )

        SetShowEditor flag ->
            ( { model | showEditor = flag }, Effect.Command.none )

        UserSignedUp user clientId ->
            ( { model
                | signupState = HideSignUpForm
                , currentUser = Just user
                , clientIds = clientId :: model.clientIds
                , maximizedIndex = MMyDocs
                , inputRealname = ""
                , inputEmail = ""
                , inputUsername = ""
                , tagSelection = TagUser
                , inputPassword = ""
                , inputPasswordAgain = ""
                , language = user.preferences.language
                , timeSignedIn = model.currentTime
                , showSignInTimer = False
              }
              -- , Effect.Lamdera.sendToBackend (GetDocumentById Types.StandardHandling Config.newsDocId)
            , Effect.Command.none
            )

        -- USER MESSAGES
        UserMessageReceived message ->
            ( { model | userMessage = Just message }, View.Chat.scrollChatToBottom )

        UndeliverableMessage _ ->
            ( model, Effect.Command.none )

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
                    ( model, Effect.Command.none )

                Just group ->
                    let
                        cmd =
                            Effect.Lamdera.sendToBackend (SendChatHistory group.name)
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
