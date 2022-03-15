module Frontend exposing (Model, app, changePrintingState, exportDoc, exportToLaTeX, fixId_, init, issueCommandIfDefined, subscriptions, update, updateDoc, updateFromBackend, urlAction, urlIsForGuest, view)

import Backend.Backup
import Browser.Events
import Browser.Navigation as Nav
import Cmd.Extra exposing (withNoCmd)
import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Debounce
import Docs
import Document
import Element
import File
import File.Download as Download
import File.Select as Select
import Frontend.Cmd
import Frontend.PDF as PDF
import Frontend.Update
import Html
import Keyboard
import Lamdera exposing (sendToBackend)
import List.Extra
import Markup
import Parser.Language exposing (Language(..))
import Process
import Render.MicroLaTeX
import Render.Settings
import Render.XMarkdown
import Task
import Types exposing (ActiveDocList(..), AppMode(..), DocLoaded(..), DocPermissions(..), DocumentDeleteState(..), FrontendModel, FrontendMsg(..), PhoneMode(..), PopupStatus(..), PrintingState(..), SortMode(..), ToBackend(..), ToFrontend(..))
import Url exposing (Url)
import UrlManager
import Util
import View.Data
import View.Main
import View.Phone


type alias Model =
    FrontendModel


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \_ -> Sub.map KeyMsg Keyboard.subscriptions
        , view = view
        }


subscriptions _ =
    Sub.batch
        [ Browser.Events.onResize (\w h -> GotNewWindowDimensions w h)
        ]


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    ( { key = key
      , url = url
      , message = "Welcome!"

      -- ADMIN
      , statusReport = []
      , inputSpecial = ""

      -- USER
      , currentUser = Nothing
      , inputUsername = ""
      , inputPassword = ""

      -- UI
      , appMode = UserMode
      , windowWidth = 600
      , windowHeight = 900
      , popupStatus = PopupClosed
      , showEditor = False
      , phoneMode = PMShowDocumentList
      , pressedKeys = []
      , activeDocList = Both

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
      , permissions = ReadOnly
      , initialText = Config.loadingText
      , documentsCreatedCounter = 0
      , sourceText = Config.loadingText
      , editRecord = Compiler.DifferentialParser.init L0Lang Config.loadingText
      , title = "Loading ..."
      , tableOfContents = Compiler.ASTTools.tableOfContents (Markup.parse L0Lang Config.loadingText)
      , debounce = Debounce.init
      , counter = 0
      , inputSearchKey = ""
      , authorId = ""
      , documents = []
      , currentDocument = Just Docs.notSignedIn
      , currentMasterDocument = Nothing
      , printingState = PrintWaiting
      , documentDeleteState = WaitingForDeleteAction
      , publicDocuments = []
      , deleteDocumentState = WaitingForDeleteAction
      , sortMode = SortByMostRecent
      , language = MicroLaTeXLang
      }
    , Cmd.batch
        [ Frontend.Cmd.setupWindow
        , urlAction url.path
        , sendToBackend GetPublicDocuments

        -- , Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById Config.welcomeDocId))
        , Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById (getId url.path)))
        ]
    )


getId : String -> String
getId path =
    let
        id =
            String.dropLeft 3 path
    in
    if id == "" then
        Config.welcomeDocId

    else
        id


urlAction : String -> Cmd FrontendMsg
urlAction path =
    let
        prefix =
            String.left 3 path

        id =
            String.dropLeft 3 path
    in
    if path == "/status/69a1c3be-4971-4673-9e0f-95456fd709a6" then
        sendToBackend GetStatus

    else
        case prefix of
            "/p/" ->
                sendToBackend (GetDocumentByPublicId id)

            "/i/" ->
                sendToBackend (GetDocumentById id)

            "/a/" ->
                sendToBackend (GetDocumentByAuthorId id)

            "/s/" ->
                sendToBackend (SearchForDocuments Nothing id)

            "/h/" ->
                sendToBackend (GetHomePage id)

            "/status/69a1c3be-4971-4673-9e0f-95456fd709a6" ->
                sendToBackend GetStatus

            _ ->
                Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById id))


urlIsForGuest : Url -> Bool
urlIsForGuest url =
    String.left 2 url.path == "/g"


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        KeyMsg keyMsg ->
            Frontend.Update.updateKeys model keyMsg

        UrlClicked urlRequest ->
            Frontend.Update.handleUrlRequest model urlRequest

        UrlChanged url ->
            -- ( model, Cmd.none )
            ( { model | url = url }
            , Cmd.batch
                [ UrlManager.handleDocId url
                ]
            )

        -- USER
        SignIn ->
            Frontend.Update.handleSignIn model

        SignOut ->
            Frontend.Update.handleSignOut model

        -- ADMIN
        ExportJson ->
            ( model, sendToBackend GetBackupData )

        JsonRequested ->
            ( model, Select.file [ "text/json" ] JsonSelected )

        JsonSelected file ->
            ( model, Task.perform JsonLoaded (File.toString file) )

        JsonLoaded jsonImport ->
            case Backend.Backup.decodeBackup jsonImport of
                Err _ ->
                    ( { model | message = "Error decoding backup" }, Cmd.none )

                Ok backendModel ->
                    ( { model | message = "restoring backup ..." }, sendToBackend (RestoreBackup backendModel) )

        InputSpecial str ->
            { model | inputSpecial = str } |> withNoCmd

        RunSpecial ->
            Frontend.Update.runSpecial model

        InputUsername str ->
            ( { model | inputUsername = str }, Cmd.none )

        InputPassword str ->
            ( { model | inputPassword = str }, Cmd.none )

        -- UI
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
            ( model, sendToBackend (GetDocumentById Config.welcomeDocId) )

        ShowTOCInPhone ->
            ( { model | phoneMode = PMShowDocumentList }, Cmd.none )

        SetDocumentInPhoneAsCurrent permissions doc ->
            Frontend.Update.setDocumentInPhoneAsCurrent model doc permissions

        SetAppMode appMode ->
            ( { model | appMode = appMode }, Cmd.none )

        GotNewWindowDimensions w h ->
            ( { model | windowWidth = w, windowHeight = h }, Cmd.none )

        GotViewport vp ->
            Frontend.Update.updateWithViewport vp model

        SetViewPortForElement result ->
            Frontend.Update.setViewportForElement model result

        InputSearchSource str ->
            ( { model | searchSourceText = str, foundIdIndex = 0 }, Cmd.none )

        GetSelection str ->
            ( { model | message = "Selection: " ++ str }, Cmd.none )

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
            ( { model | showEditor = False, initialText = "" }, sendToBackend GetPublicDocuments )

        OpenEditor ->
            case model.currentDocument of
                Nothing ->
                    ( { model | message = "No document to open in editor" }, Cmd.none )

                Just doc ->
                    ( { model | showEditor = True, sourceText = doc.content, initialText = "" }, Frontend.Cmd.setInitialEditorContent 20 )

        Help docId ->
            ( model, sendToBackend (GetDocumentByAuthorId docId) )

        -- DOCUMENT
        CycleLanguage ->
            Frontend.Update.cycleLanguage model

        Render msg_ ->
            Frontend.Update.render model msg_

        Fetch id ->
            ( model, sendToBackend (FetchDocumentById id (Maybe.map .username model.currentUser)) )

        DebounceMsg msg_ ->
            Frontend.Update.debounceMsg model msg_

        Saved str ->
            updateDoc model str

        Search ->
            ( model, sendToBackend (SearchForDocuments (model.currentUser |> Maybe.map .username) model.inputSearchKey) )

        SearchText ->
            Frontend.Update.searchText model

        InputText str ->
            Frontend.Update.inputText model str

        SetInitialEditorContent ->
            Frontend.Update.setInitialEditorContent model

        InputAuthorId str ->
            ( { model | authorId = str }, Cmd.none )

        AskFoDocumentById id ->
            ( model, sendToBackend (GetDocumentByAuthorId id) )

        AskForDocumentByAuthorId ->
            ( model, sendToBackend (GetDocumentByAuthorId model.authorId) )

        InputSearchKey str ->
            ( { model | inputSearchKey = str }, Cmd.none )

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
    case ( model.currentDocument, model.currentUser ) of
        ( Nothing, _ ) ->
            ( model, Cmd.none )

        ( _, Nothing ) ->
            ( model, Cmd.none )

        ( Just doc, Just user ) ->
            if Just user.username /= doc.author then
                ( model, Cmd.none )

            else
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
                        List.Extra.setIf (\d -> d.id == newDocument.id) newDocument model.documents
                in
                ( { model
                    | currentDocument = Just newDocument
                    , counter = model.counter + 1
                    , documents = documents
                  }
                , sendToBackend (SaveDocument model.currentUser newDocument)
                )


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
        -- DOCUMENT
        SendDocument access doc ->
            let
                documents =
                    Util.insertInListViaTitle doc model.documents

                showEditor =
                    case access of
                        ReadOnly ->
                            False

                        CanEdit ->
                            True

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

                -- , showEditor = showEditor
                , currentDocument = Just doc
                , sourceText = doc.content
                , currentMasterDocument = currentMasterDocument
                , documents = documents
                , counter = model.counter + 1
              }
            , Frontend.Cmd.setInitialEditorContent 20
            )

        GotPublicDocuments publicDocuments ->
            ( { model | publicDocuments = publicDocuments }, Cmd.none )

        SendMessage message ->
            ( { model | message = message }, Cmd.none )

        -- ADMIN
        SendBackupData data ->
            ( { model | message = "Backup data: " ++ String.fromInt (String.length data) ++ " chars" }, Download.string "l0-lab-demo    .json" "text/json" data )

        StatusReport items ->
            ( { model | statusReport = items }, Cmd.none )

        SetShowEditor flag ->
            ( { model | showEditor = flag }, Cmd.none )

        -- USER
        SendUser user ->
            ( { model | currentUser = Just user }, Cmd.none )

        SendDocuments documents ->
            ( { model | documents = documents }, Cmd.none )


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
