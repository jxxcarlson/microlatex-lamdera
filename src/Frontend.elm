module Frontend exposing (Model, app, changePrintingState, exportDoc, exportToLaTeX, fixId_, init, issueCommandIfDefined, subscriptions, update, updateFromBackend, urlAction, urlIsForGuest, view)

import Chat
import Chat.Message
import Cmd.Extra exposing (withNoCmd)
import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OT as OT
import CollaborativeEditing.OTCommand as OTCommand
import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Debounce
import Deque
import Dict
import Docs
import Document
import DocumentTools
import Duration
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Command as Command exposing (Command)
import Effect.File.Download as Download
import Effect.Lamdera exposing (sendToBackend)
import Effect.Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task
import Effect.Time
import Element
import Env
import Frontend.Cmd
import Frontend.PDF as PDF
import Frontend.Update
import Html
import Keyboard
import Lamdera
import Markup
import Message
import Parser.Language exposing (Language(..))
import Predicate
import Render.MicroLaTeX
import Render.XMarkdown
import Share
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


init : Url.Url -> Effect.Browser.Navigation.Key -> ( Model, Command restriction toMsg FrontendMsg )
init url key =
    ( { key = key
      , url = url
      , messages = [ { txt = "Welcome!", status = MSWhite } ]
      , currentTime = Effect.Time.millisToPosix 0
      , zone = Effect.Time.utc
      , timeSignedIn = Effect.Time.millisToPosix 0
      , lastInteractionTime = Effect.Time.millisToPosix 0

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
      , selectedSlug = Nothing
      , searchCount = 0
      , searchSourceText = ""
      , syncRequestIndex = 0

      -- COLLABORATIVE EDITING
      , editCommand = { counter = -1, command = Nothing }
      , editorEvent = { counter = 0, cursor = 0, event = Nothing }
      , eventQueue = Deque.empty
      , collaborativeEditing = False
      , editorCursor = 0
      , myCursorPosition = { x = 0, y = 0, p = 0 }
      , networkModel = NetworkModel.init (NetworkModel.initialServerState "foo" "bar" "baz")

      -- SHARED EDITING
      , activeEditor = Nothing

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
      , currentManual = Nothing
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
    , Command.batch
        [ Frontend.Cmd.setupWindow
        , urlAction url.path
        , if url.path == "/" then
            Effect.Lamdera.sendToBackend (SearchForDocuments StandardHandling Nothing "jxxcarlson:system-home")
            -- searchForPublicDocuments sortMode limit mUsername key model

          else
            Command.none
        , Effect.Task.perform AdjustTimeZone Effect.Time.here
        , case Env.mode of
            Env.Development ->
                Effect.Lamdera.sendToBackend ClearConnectionDictBE

            Env.Production ->
                Command.none

        --- TODO: ???, sendToBackend GetCheatSheetDocument
        ]
    )


urlAction : String -> Command restriction toMsg FrontendMsg
urlAction path =
    let
        prefix =
            String.left 3 path

        segment =
            String.dropLeft 3 path
    in
    if prefix == "/" then
        Effect.Lamdera.sendToBackend (GetDocumentById Types.StandardHandling Config.welcomeDocId)

    else
        case prefix of
            "/i/" ->
                Effect.Lamdera.sendToBackend (GetDocumentById Types.StandardHandling segment)

            "/a/" ->
                Effect.Lamdera.sendToBackend (SearchForDocumentsWithAuthorAndKey segment)

            "/s/" ->
                Effect.Lamdera.sendToBackend (SearchForDocuments StandardHandling Nothing segment)

            "/h/" ->
                Effect.Lamdera.sendToBackend (GetHomePage segment)

            _ ->
                --Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById id))
                Effect.Lamdera.sendToBackend (GetDocumentById Types.StandardHandling Config.welcomeDocId)


urlIsForGuest : Url -> Bool
urlIsForGuest url =
    String.left 2 url.path == "/g"


update : FrontendMsg -> Model -> ( Model, Command restriction toMsg FrontendMsg )
update msg model =
    case msg of
        FENoOp ->
            ( model, Command.none )

        SetDocumentStatus status ->
            case model.currentDocument of
                Nothing ->
                    ( model, Command.none )

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
                    model.lastInteractionTime |> Effect.Time.posixToMillis

                currentTimeMilliseconds =
                    model.currentTime |> Effect.Time.posixToMillis

                elapsedSinceLastInteractionSeconds =
                    (currentTimeMilliseconds - lastInteractionTimeMilliseconds) // 1000

                activeEditor =
                    case model.activeEditor of
                        Nothing ->
                            Nothing

                        Just { name, activeAt } ->
                            if Effect.Time.posixToMillis activeAt < (Effect.Time.posixToMillis model.currentTime - (Config.editSafetyInterval * 1000)) then
                                Nothing

                            else
                                model.activeEditor
            in
            -- If the lastInteractionTime has not been updated since init, do so now.
            if model.lastInteractionTime == Effect.Time.millisToPosix 0 && model.currentUser /= Nothing then
                ( { model | activeEditor = activeEditor, currentTime = newTime, lastInteractionTime = newTime }, Command.none )

            else if elapsedSinceLastInteractionSeconds >= Config.automaticSignoutLimit && model.currentUser /= Nothing then
                Frontend.Update.signOut { model | currentTime = newTime }

            else
                ( { model | activeEditor = activeEditor, currentTime = newTime }, Command.none )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }, Command.none )

        GotTime timeNow ->
            ( model, Command.none )

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
            ( model, Effect.Lamdera.sendToBackend (ClearChatHistory model.inputGroup) )

        SetChatGroup ->
            case model.currentUser of
                Nothing ->
                    ( model, Command.none )

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
                            ( [], Effect.Lamdera.sendToBackend (SendChatHistory (String.trim model.inputGroup)) )

                        --if Just (String.trim model.inputGroup) == oldPreferences.group then
                        --    ( model.chatMessages, Cmd.none )
                        --
                        --else
                        --    ( [], sendToBackend (SendChatHistory (String.trim model.inputGroup)) )
                    in
                    ( { model | currentUser = Just revisedUser, chatMessages = updatedChatMessages }, Command.batch [ cmd, Effect.Lamdera.sendToBackend (UpdateUserWith revisedUser) ] )

        GetChatHistory ->
            ( model, Command.batch [ Effect.Lamdera.sendToBackend (SendChatHistory model.inputGroup) ] )

        ScrollChatToBottom ->
            ( model, View.Chat.scrollChatToBottom )

        CreateChatGroup ->
            case model.currentUser of
                Nothing ->
                    ( { model | chatDisplay = Types.TCGDisplay }, Command.none )

                Just user ->
                    let
                        newChatGroup =
                            { name = model.inputGroupName
                            , owner = user.username
                            , assistant = Just model.inputGroupAssistant
                            , members = model.inputGroupMembers |> String.split "," |> List.map String.trim
                            }
                    in
                    ( { model | chatDisplay = Types.TCGDisplay, currentChatGroup = Just newChatGroup }, Effect.Lamdera.sendToBackend (InsertChatGroup newChatGroup) )

        SetChatDisplay option ->
            ( { model | chatDisplay = option }, Command.none )

        InputGroupName str ->
            ( { model | inputGroupName = str }, Command.none )

        InputGroupAssistant str ->
            ( { model | inputGroupAssistant = str }, Command.none )

        InputGroupMembers str ->
            ( { model | inputGroupMembers = str }, Command.none )

        InputChoseGroup str ->
            ( { model | inputGroup = str }, Effect.Lamdera.sendToBackend (GetChatGroup str) )

        TogglePublicUrl ->
            ( { model | showPublicUrl = not model.showPublicUrl }, Command.none )

        -- CHAT
        ToggleChat ->
            ( { model | chatVisible = not model.chatVisible, chatMessages = [] }, Command.batch [ Util.delay 200 ScrollChatToBottom, Effect.Lamdera.sendToBackend (SendChatHistory model.inputGroup) ] )

        ToggleDocTools ->
            ( { model | showDocTools = not model.showDocTools }, Command.none )

        MessageFieldChanged str ->
            ( { model | chatMessageFieldContent = str }, Command.none )

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
            , Command.batch
                [ Effect.Lamdera.sendToBackend (ChatMsgSubmitted chatMessage)
                , View.Chat.focusMessageInput
                , View.Chat.scrollChatToBottom
                ]
            )

        -- USER MESSAGES
        DismissUserMessage ->
            ( { model | userMessage = Nothing }, Command.none )

        SendUserMessage message ->
            ( { model | userMessage = Nothing }, Effect.Lamdera.sendToBackend (DeliverUserMessage message) )

        OpenSharedDocumentList ->
            ( model
            , Effect.Lamdera.sendToBackend (GetSharedDocuments (model.currentUser |> Maybe.map .username |> Maybe.withDefault "(anon)"))
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
                , messages = []
              }
            , Command.none
            )

        DoSignUp ->
            Frontend.Update.handleSignUp model

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
            { model | inputSpecial = str } |> withNoCmd

        RunSpecial ->
            Frontend.Update.runSpecial model

        InputUsername str ->
            ( { model | inputUsername = str }, Command.none )

        InputPassword str ->
            ( { model | inputPassword = str }, Command.none )

        InputPasswordAgain str ->
            ( { model | inputPasswordAgain = str }, Command.none )

        InputRealname str ->
            ( { model | inputRealname = str }, Command.none )

        InputEmail str ->
            ( { model | inputEmail = str }, Command.none )

        -- UI
        ToggleCheatsheet ->
            case model.popupState of
                NoPopup ->
                    let
                        id =
                            case model.language of
                                L0Lang ->
                                    Config.l0GuideId

                                MicroLaTeXLang ->
                                    Config.microLaTeXGuideId

                                XMarkdownLang ->
                                    Config.xmarkdownGuideId

                                PlainTextLang ->
                                    Config.plainTextCheatsheetId
                    in
                    ( { model | popupState = GuidesPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual id) )

                _ ->
                    ( { model | popupState = NoPopup }, Command.none )

        ToggleManuals manualType ->
            case model.popupState of
                NoPopup ->
                    case manualType of
                        Types.TManual ->
                            case model.language of
                                L0Lang ->
                                    ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.l0ManualId) )

                                MicroLaTeXLang ->
                                    ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.microLaTeXManualId) )

                                XMarkdownLang ->
                                    ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.xmarkdownId) )

                                PlainTextLang ->
                                    ( { model | popupState = NoPopup }, Command.none )

                        Types.TGuide ->
                            case model.language of
                                L0Lang ->
                                    ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.l0GuideId) )

                                MicroLaTeXLang ->
                                    ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.microLaTeXGuideId) )

                                XMarkdownLang ->
                                    ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.xmarkdownGuideId) )

                                PlainTextLang ->
                                    ( { model | popupState = NoPopup }, Command.none )

                ManualsPopup ->
                    case manualType of
                        Types.TManual ->
                            if
                                List.member (Maybe.andThen Document.getSlug model.currentManual)
                                    [ Just Config.l0ManualId, Just Config.microLaTeXManualId, Just Config.microLaTeXManualId ]
                            then
                                ( { model | popupState = NoPopup }, Command.none )

                            else
                                case model.language of
                                    L0Lang ->
                                        ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.l0ManualId) )

                                    MicroLaTeXLang ->
                                        ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.microLaTeXManualId) )

                                    XMarkdownLang ->
                                        ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.xmarkdownId) )

                                    PlainTextLang ->
                                        ( { model | popupState = NoPopup }, Command.none )

                        Types.TGuide ->
                            if
                                List.member (Maybe.andThen Document.getSlug model.currentManual)
                                    [ Just Config.l0GuideId, Just Config.microLaTeXGuideId, Just Config.microLaTeXGuideId ]
                            then
                                ( { model | popupState = NoPopup }, Command.none )

                            else
                                case model.language of
                                    L0Lang ->
                                        ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.l0GuideId) )

                                    MicroLaTeXLang ->
                                        ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.microLaTeXGuideId) )

                                    XMarkdownLang ->
                                        ( { model | popupState = ManualsPopup }, Effect.Lamdera.sendToBackend (FetchDocumentById HandleAsManual Config.xmarkdownGuideId) )

                                    PlainTextLang ->
                                        ( { model | popupState = NoPopup }, Command.none )

                _ ->
                    ( { model | popupState = NoPopup }, Command.none )

        SelectList list ->
            let
                cmd =
                    if list == SharedDocumentList then
                        Effect.Lamdera.sendToBackend (GetSharedDocuments (model.currentUser |> Maybe.map .username |> Maybe.withDefault "(anon)"))

                    else if list == PinnedDocs then
                        Effect.Lamdera.sendToBackend (SearchForDocuments PinnedDocumentList (model.currentUser |> Maybe.map .username) "pin")

                    else
                        Command.none
            in
            ( { model | lastInteractionTime = model.currentTime, documentList = list }, cmd )

        ChangePopup popupState ->
            ( { model | popupState = popupState }, Command.none )

        ToggleIndexSize ->
            case model.maximizedIndex of
                MMyDocs ->
                    ( { model | maximizedIndex = MPublicDocs }, Command.none )

                MPublicDocs ->
                    ( { model | maximizedIndex = MMyDocs }, Command.none )

        CloseCollectionIndex ->
            ( { model | currentMasterDocument = Nothing }
            , Command.none
            )

        ToggleActiveDocList ->
            case model.currentMasterDocument of
                Nothing ->
                    ( { model | activeDocList = Both }, Command.none )

                Just _ ->
                    case model.activeDocList of
                        PublicDocsList ->
                            ( { model | activeDocList = PrivateDocsList }, Command.none )

                        PrivateDocsList ->
                            ( { model | activeDocList = PublicDocsList }, Command.none )

                        Both ->
                            ( { model | activeDocList = PrivateDocsList }, Command.none )

        Home ->
            ( model, Effect.Lamdera.sendToBackend (GetDocumentById Types.StandardHandling Config.welcomeDocId) )

        ShowTOCInPhone ->
            ( { model | phoneMode = PMShowDocumentList }, Command.none )

        SetDocumentInPhoneAsCurrent permissions doc ->
            Frontend.Update.setDocumentInPhoneAsCurrent model doc permissions

        SetAppMode appMode ->
            let
                cmd =
                    case appMode of
                        UserMode ->
                            Command.none

                        AdminMode ->
                            Effect.Lamdera.sendToBackend GetUserList
            in
            ( { model | appMode = appMode }, cmd )

        GotNewWindowDimensions w h ->
            ( { model | windowWidth = w, windowHeight = h }, Command.none )

        GotViewport vp ->
            Frontend.Update.updateWithViewport vp model

        SetViewPortForElement result ->
            Frontend.Update.setViewportForElement model result

        InputSearchSource str ->
            ( { model | searchSourceText = str, foundIdIndex = 0 }, Command.none )

        GetSelection str ->
            ( { model | messages = [ { txt = "Selection: " ++ str, status = MSWhite } ] }, Command.none )

        -- SYNC
        SelectedText str ->
            Frontend.Update.firstSyncLR model str

        SendSyncLR ->
            ( { model | syncRequestIndex = model.syncRequestIndex + 1 }, Command.none )

        SyncLR ->
            Frontend.Update.syncLR model

        StartSync ->
            ( { model | doSync = not model.doSync }, Command.none )

        NextSync ->
            Frontend.Update.nextSyncLR model

        ChangePopupStatus status ->
            ( { model | popupStatus = status }, Command.none )

        NoOpFrontendMsg ->
            ( model, Command.none )

        CloseEditor ->
            Frontend.Update.closeEditor model

        OpenEditor ->
            case model.currentDocument of
                Nothing ->
                    ( { model | messages = [ { txt = "No document to open in editor", status = MSWhite } ] }, Command.none )

                Just doc ->
                    Frontend.Update.openEditor doc model

        Help docId ->
            ( model, Effect.Lamdera.sendToBackend (SearchForDocumentsWithAuthorAndKey docId) )

        -- SHARE
        Narrow username document ->
            ( model, Effect.Lamdera.sendToBackend (Narrowcast (Util.currentUserId model.currentUser) username document) )

        -- DOCUMENT
        ChangeLanguage ->
            case model.currentDocument of
                Nothing ->
                    ( model, Command.none )

                Just doc ->
                    let
                        newDocument =
                            { doc | language = model.language }
                    in
                    ( model
                    , Effect.Lamdera.sendToBackend (SaveDocument model.currentUser newDocument)
                    )
                        |> (\( m, c ) -> ( Frontend.Update.postProcessDocument newDocument m, c ))

        ToggleBackupVisibility ->
            ( { model | seeBackups = not model.seeBackups }, Command.none )

        MakeBackup ->
            case ( model.currentUser, model.currentDocument ) of
                ( Nothing, _ ) ->
                    ( model, Command.none )

                ( _, Nothing ) ->
                    ( model, Command.none )

                ( Just user, Just doc ) ->
                    if Just user.username == doc.author then
                        let
                            newDocument =
                                Document.makeBackup doc
                        in
                        ( model, Effect.Lamdera.sendToBackend (InsertDocument user newDocument) )

                    else
                        ( model, Command.none )

        InputReaders str ->
            ( { model | inputReaders = str }, Command.none )

        InputEditors str ->
            ( { model | inputEditors = str }, Command.none )

        ShareDocument ->
            Share.shareDocument model

        DoShare ->
            Share.doShare model

        ToggleCollaborativeEditing ->
            case model.currentDocument of
                Nothing ->
                    ( model, Command.none )

                Just doc ->
                    case model.collaborativeEditing of
                        False ->
                            ( model, Effect.Lamdera.sendToBackend (InitializeNetworkModelsWithDocument doc) )

                        True ->
                            ( model, Effect.Lamdera.sendToBackend (ResetNetworkModelForDocument doc) )

        GetPinnedDocuments ->
            ( { model | documentList = StandardList }, Effect.Lamdera.sendToBackend (SearchForDocuments PinnedDocumentList (model.currentUser |> Maybe.map .username) "pin") )

        -- TAGS
        GetUserTags ->
            ( { model | tagSelection = TagUser }, Command.none )

        GetPublicTags ->
            ( { model | tagSelection = TagPublic }, Command.none )

        ToggleExtrasSidebar ->
            case model.sidebarExtrasState of
                SidebarExtrasIn ->
                    ( { model | sidebarExtrasState = SidebarExtrasOut, sidebarTagsState = SidebarTagsIn }
                    , Effect.Lamdera.sendToBackend GetUsersWithOnlineStatus
                    )

                SidebarExtrasOut ->
                    ( { model | sidebarExtrasState = SidebarExtrasIn }, Command.none )

        ToggleTagsSidebar ->
            let
                tagSelection =
                    model.tagSelection
            in
            case model.sidebarTagsState of
                SidebarTagsIn ->
                    ( { model | sidebarExtrasState = SidebarExtrasIn, sidebarTagsState = SidebarTagsOut }
                    , Command.batch
                        [ Effect.Lamdera.sendToBackend GetPublicTagsFromBE
                        , Effect.Lamdera.sendToBackend (GetUserTagsFromBE (Util.currentUsername model.currentUser))
                        ]
                    )

                SidebarTagsOut ->
                    ( { model | messages = Message.make "Tags in" MSYellow, tagSelection = tagSelection, sidebarTagsState = SidebarTagsIn }, Command.none )

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
            -- This is the only route to function updateDoc, updateDoc_
            if Predicate.documentIsMineOrIAmAnEditor model.currentDocument model.currentUser then
                Frontend.Update.updateDoc model str

            else
                ( model, Command.none )

        Search ->
            ( { model
                | actualSearchKey = model.inputSearchKey
                , documentList = StandardList
                , currentMasterDocument = Nothing
              }
            , Effect.Lamdera.sendToBackend (SearchForDocuments StandardHandling (model.currentUser |> Maybe.map .username) model.inputSearchKey)
            )

        SearchText ->
            Frontend.Update.searchText model

        InputText { position, source } ->
            Frontend.Update.inputText model { position = position, source = source }

        InputCommand str ->
            ( { model | inputCommand = str }, Command.none )

        InputCursor { position, source } ->
            Frontend.Update.inputCursor { position = position, source = source } model

        InputTitle str ->
            Frontend.Update.inputTitle model str

        SetInitialEditorContent ->
            Frontend.Update.setInitialEditorContent model

        InputAuthorId str ->
            ( { model | authorId = str }, Command.none )

        AskForDocumentById documentHandling id ->
            ( model, Effect.Lamdera.sendToBackend (GetDocumentById documentHandling id) )

        AskForDocumentByAuthorId ->
            ( model, Effect.Lamdera.sendToBackend (SearchForDocumentsWithAuthorAndKey model.authorId) )

        InputSearchKey str ->
            ( { model | inputSearchKey = str }, Command.none )

        InputSearchTagsKey str ->
            ( { model | inputSearchTagsKey = str }, Command.none )

        NewDocument ->
            Frontend.Update.newDocument model

        SetDeleteDocumentState s ->
            ( { model | deleteDocumentState = s }, Command.none )

        SetHardDeleteDocumentState s ->
            ( { model | hardDeleteDocumentState = s }, Command.none )

        SoftDeleteDocument ->
            Frontend.Update.softDeleteDocument model

        HardDeleteDocument ->
            Frontend.Update.hardDeleteDocument model

        SetPublicDocumentAsCurrentById id ->
            Frontend.Update.setPublicDocumentAsCurrentById model id

        SetDocumentCurrent document ->
            case model.currentDocument of
                Nothing ->
                    Frontend.Update.setDocumentAsCurrent Command.none model document StandardHandling

                Just currentDocument ->
                    Frontend.Update.handleCurrentDocumentChange model currentDocument document

        -- Handles button clicks
        SetDocumentAsCurrent handling document ->
            case model.currentDocument of
                Nothing ->
                    Frontend.Update.setDocumentAsCurrent Command.none model document handling

                Just currentDocument ->
                    Frontend.Update.handleCurrentDocumentChange model currentDocument document

        SetDocumentCurrentViaId id ->
            case Document.documentFromListViaId id model.documents of
                Nothing ->
                    ( model, Command.none )

                Just doc ->
                    ( Frontend.Update.postProcessDocument doc model, Command.none )

        SetPublic doc public ->
            Frontend.Update.setPublic model doc public

        SetSortMode sortMode ->
            ( { model | sortMode = sortMode }, Command.none )

        -- Export
        ExportToMarkdown ->
            Frontend.Update.exportToMarkdown model

        ExportToLaTeX ->
            Frontend.Update.exportToLaTeX model

        ExportToRawLaTeX ->
            Frontend.Update.exportToRawLaTeX model

        ExportTo lang ->
            case model.currentDocument of
                Nothing ->
                    ( model, Command.none )

                Just doc ->
                    case lang of
                        MicroLaTeXLang ->
                            let
                                ast =
                                    model.editRecord.parsed

                                newText =
                                    Render.MicroLaTeX.export ast
                            in
                            ( model, Effect.File.Download.string "out-microlatex.txt" "text/plain" newText )

                        L0Lang ->
                            ( model, Effect.File.Download.string "out-l0.txt" "text/plain" doc.content )

                        PlainTextLang ->
                            ( model, Effect.File.Download.string "out-l0.txt" "text/plain" doc.content )

                        XMarkdownLang ->
                            let
                                ast =
                                    model.editRecord.parsed

                                newText =
                                    Render.XMarkdown.export ast
                            in
                            ( model, Effect.File.Download.string "out-xmarkdown.txt" "text/plain" newText )

        Export ->
            issueCommandIfDefined model.currentDocument model exportDoc

        RunCommand ->
            ( { model | counter = model.counter + 1, editCommand = { counter = model.counter, command = OTCommand.parseCommand model.inputCommand } }, Command.none )

        PrintToPDF ->
            PDF.print model

        GotPdfLink result ->
            PDF.gotLink model result

        ChangePrintingState printingState ->
            -- TODO: review this
            issueCommandIfDefined model.currentDocument { model | printingState = printingState } (changePrintingState printingState)

        FinallyDoCleanPrintArtefacts _ ->
            ( model, Command.none )


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
--    -- ( { model | messages = [ { txt = m, status = MSYellow } ] }, sendToBackend (Narrowcast (Util.currentUserId model.currentUser) (Util.currentUsername model.currentUser) doc) )
--    -- ( { model | messages = [ { txt = m, status = MSYellow } ] }, Cmd.none )
--    -- ( { model | messages = [ { txt = m, status = MSYellow } ] }, sendToBackend (NarrowcastExceptToSender (Util.currentUserId model.currentUser) (Util.currentUsername model.currentUser) doc) )
--    ( { model | messages = [ { txt = m, status = MSYellow } ] }, Cmd.none )


changePrintingState : PrintingState -> { a | id : String } -> Command restriction toMsg FrontendMsg
changePrintingState printingState doc =
    if printingState == PrintWaiting then
        Effect.Process.sleep 1000 |> Effect.Task.perform (always (FinallyDoCleanPrintArtefacts doc.id))

    else
        Command.none


exportToLaTeX : Document.Document -> Command restriction toMsg msg
exportToLaTeX doc =
    let
        laTeXText =
            ""

        fileName =
            doc.id ++ ".lo"
    in
    Effect.File.Download.string fileName "application/x-latex" laTeXText


exportDoc : Document.Document -> Command restriction toMsg msg
exportDoc doc =
    let
        fileName =
            doc.id ++ ".l0"
    in
    Effect.File.Download.string fileName "text/plain" doc.content


issueCommandIfDefined : Maybe a -> Model -> (a -> Command restriction toMsg msg) -> ( Model, Command restriction toMsg msg )
issueCommandIfDefined maybeSomething model cmdMsg =
    case maybeSomething of
        Nothing ->
            ( model, Command.none )

        Just something ->
            ( model, cmdMsg something )


updateFromBackend : ToFrontend -> Model -> ( Model, Command restriction toMsg FrontendMsg )
updateFromBackend msg model =
    case msg of
        -- ADMIN
        GotShareDocumentList sharedDocList ->
            ( { model | sharedDocumentList = sharedDocList }, Command.none )

        GotUsersWithOnlineStatus userData ->
            ( { model | userList = userData }, Command.none )

        GotConnectionList connectedUsers ->
            ( { model | connectedUsers = connectedUsers }, Command.none )

        -- COLLABORATIVE EDITING
        InitializeNetworkModel networkModel ->
            ( { model
                | collaborativeEditing = True
                , networkModel = networkModel
                , editCommand = { counter = model.counter, command = Just (OTCommand.CMoveCursor 0 0) }
              }
            , Command.none
            )

        ResetNetworkModel networkModel document ->
            ( { model
                | collaborativeEditing = False
                , networkModel = networkModel
                , currentDocument = Just document
                , documents = Util.updateDocumentInList document model.documents
                , showEditor = False
              }
            , Command.none
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
            , Command.none
            )

        AcceptUserTags tagDict ->
            ( { model | tagDict = tagDict }, Command.none )

        AcceptPublicTags tagDict ->
            ( { model | publicTagDict = tagDict }, Command.none )

        -- COLLABORATIVE EDITING
        ProcessEvent event ->
            let
                debugLabel =
                    "P1a. !!! EVENT FOR " ++ Util.currentUsername model.currentUser

                newNetworkModel =
                    NetworkModel.updateFromBackend NetworkModel.applyEvent
                        event
                        model.networkModel

                doc : OT.Document
                doc =
                    NetworkModel.getLocalDocument newNetworkModel

                newEditRecord : Compiler.DifferentialParser.EditRecord
                newEditRecord =
                    Compiler.DifferentialParser.init model.includedContent model.language doc.content

                editCommand =
                    if Util.currentUserId model.currentUser /= event.userId then
                        { counter = model.counter, command = event |> OTCommand.toCommand }

                    else
                        { counter = model.counter, command = Nothing }
            in
            ( { model
                | editCommand = editCommand

                -- editorEvent = { counter = model.counter, cursor = cursor, event = editorEvent }
                -- TODO!!
                -- ,  eventQueue = Deque.pushFront event model.eventQueue
                , networkModel = newNetworkModel
                , editRecord = newEditRecord
              }
            , Command.none
            )

        ReceivedDocument documentHandling doc ->
            case documentHandling of
                StandardHandling ->
                    Frontend.Update.handleAsStandardReceivedDocument model doc

                HandleSharedDocument username ->
                    Frontend.Update.handleSharedDocument model username doc

                DelayedHandling ->
                    Frontend.Update.handleAsReceivedDocumentWithDelay model doc

                PinnedDocumentList ->
                    Frontend.Update.handleAsStandardReceivedDocument model doc

                HandleAsManual ->
                    Frontend.Update.handleReceivedDocumentAsCheatsheet model doc

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
                , documents = doc :: model.documents -- insertInListOrUpdate
                , currentDocument = Just doc
                , sourceText = doc.content
                , currentMasterDocument = currentMasterDocument
                , counter = model.counter + 1
              }
            , Command.batch [ Util.delay 40 (SetDocumentCurrent doc), Frontend.Cmd.setInitialEditorContent 20, View.Utility.setViewPortToTop model.popupState ]
            )

        ReceivedPublicDocuments publicDocuments ->
            case List.head publicDocuments of
                Nothing ->
                    ( { model | publicDocuments = publicDocuments }, Command.none )

                Just doc ->
                    let
                        cmd =
                            case model.currentUser of
                                Nothing ->
                                    if model.actualSearchKey == "" && model.url.path == "/" then
                                        Command.none

                                    else
                                        Util.delay 40 (SetDocumentCurrent doc)

                                Just _ ->
                                    Util.delay 40 (SetDocumentCurrent doc)
                    in
                    ( { model | publicDocuments = publicDocuments }, cmd )

        ReceivedDocuments documentHandling documents_ ->
            let
                documents =
                    DocumentTools.sort model.sortMode documents_
            in
            case List.head documents of
                Nothing ->
                    -- ( model, sendToBackend (FetchDocumentById DelayedHandling Config.notFoundDocId) )
                    ( model, Command.none )

                Just doc ->
                    case documentHandling of
                        PinnedDocumentList ->
                            ( { model | pinnedDocuments = List.map Document.toDocInfo documents, currentDocument = Just doc }
                            , Command.none
                              -- TODO: ??, Cmd.batch [ Util.delay 40 (SetDocumentCurrent doc) ]
                            )

                        _ ->
                            ( { model | documents = documents, currentDocument = Just doc } |> Frontend.Update.postProcessDocument doc
                            , Command.none
                            )

        MessageReceived message ->
            let
                newMessages =
                    if List.member message.status [ Types.MSRed, Types.MSYellow, Types.MSGreen ] then
                        [ message ]

                    else
                        model.messages
            in
            ( { model | messages = newMessages }, Command.none )

        -- ADMIN
        SendBackupData data ->
            ( { model | messages = [ { txt = "Backup data: " ++ String.fromInt (String.length data) ++ " chars", status = MSWhite } ] }, Effect.File.Download.string "l0-lab-demo    .json" "text/json" data )

        StatusReport items ->
            ( { model | statusReport = items }, Command.none )

        SetShowEditor flag ->
            ( { model | showEditor = flag }, Command.none )

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
            , Command.none
            )

        -- USER MESSAGES
        UserMessageReceived message ->
            ( { model | userMessage = Just message }, View.Chat.scrollChatToBottom )

        UndeliverableMessage message ->
            ( model, Command.none )

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
                    ( model, Command.none )

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
