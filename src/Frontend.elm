module Frontend exposing (Model, adjustId, app, changePrintingState, debounceConfig, exportDoc, exportToLaTeX, firstSyncLR, fixId_, init, issueCommandIfDefined, nextSyncLR, save, setPermissions, subscriptions, update, updateDoc, updateFromBackend, urlAction, urlIsForGuest, view)

import Authentication
import Backend.Backup
import Browser exposing (UrlRequest(..))
import Browser.Events
import Browser.Navigation as Nav
import Cmd.Extra exposing (withCmd, withNoCmd)
import Compiler.ASTTools
import Compiler.Acc
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
import Render.LaTeX as LaTeX
import Render.Markup as L0
import Render.Msg exposing (L0Msg(..))
import Render.Settings as Settings
import Task
import Types exposing (..)
import Url exposing (Url)
import UrlManager
import Util
import View.Data
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
        , subscriptions = \_ -> Sub.map KeyMsg Keyboard.subscriptions
        , view = view
        }


subscriptions model =
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
      , initialText = ""
      , documentsCreatedCounter = 0
      , sourceText = View.Data.welcome
      , editRecord = Compiler.DifferentialParser.init Config.initialLanguage ""
      , title = "(title not yet defined)"
      , tableOfContents = Compiler.ASTTools.tableOfContents (Markup.parse MicroLaTeXLang View.Data.welcome)
      , debounce = Debounce.init
      , counter = 0
      , inputSearchKey = ""
      , authorId = ""
      , documents = []
      , currentDocument = Just Docs.notSignedIn
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
        ]
    )


debounceConfig : Debounce.Config FrontendMsg
debounceConfig =
    { strategy = Debounce.soon 300
    , transform = DebounceMsg
    }


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
                Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById Config.welcomeDocId))


urlIsForGuest : Url -> Bool
urlIsForGuest url =
    String.left 2 url.path == "/g"


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        KeyMsg keyMsg ->
            let
                pressedKeys =
                    Keyboard.update keyMsg model.pressedKeys

                doSync =
                    if List.member Keyboard.Control pressedKeys && List.member (Keyboard.Character "S") pressedKeys then
                        not model.doSync

                    else
                        model.doSync
            in
            ( { model | pressedKeys = pressedKeys, doSync = doSync }
            , Cmd.none
            )

        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    let
                        cmd =
                            case .fragment url of
                                Just internalId ->
                                    -- internalId is the part after '#', if present
                                    View.Utility.setViewportForElement internalId

                                Nothing ->
                                    --if String.left 3 url.path == "/a/" then
                                    sendToBackend (GetDocumentByAuthorId (String.dropLeft 3 url.path))

                        --
                        --else if String.left 3 url.path == "/p/" then
                        --    sendToBackend (GetDocumentByPublicId (String.dropLeft 3 url.path))
                        --
                        --else
                        --    Nav.pushUrl model.key (Url.toString url)
                    in
                    ( model, cmd )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            -- ( model, Cmd.none )
            ( { model | url = url }
            , Cmd.batch
                [ UrlManager.handleDocId url
                ]
            )

        -- USER
        SignIn ->
            if String.length model.inputPassword >= 8 then
                ( model
                , sendToBackend (SignInOrSignUp model.inputUsername (Authentication.encryptForTransit model.inputPassword))
                )

            else
                ( { model | message = "Password must be at least 8 letters long." }, Cmd.none )

        SignOut ->
            ( { model
                | currentUser = Nothing
                , currentDocument = Just Docs.notSignedIn
                , documents = []
                , message = "Signed out"
                , inputSearchKey = ""
                , inputUsername = ""
                , inputPassword = ""
                , showEditor = False
              }
            , -- Cmd.none
              Nav.pushUrl model.key "/"
            )

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
            case model.currentUser of
                Nothing ->
                    model |> withNoCmd

                Just user ->
                    if user.username == "jxxcarlson" then
                        model |> withCmd (sendToBackend (ApplySpecial user model.inputSpecial))

                    else
                        model |> withNoCmd

        InputUsername str ->
            ( { model | inputUsername = str }, Cmd.none )

        InputPassword str ->
            ( { model | inputPassword = str }, Cmd.none )

        -- UI
        Home ->
            ( model, sendToBackend (GetDocumentById Config.welcomeDocId) )

        ShowTOCInPhone ->
            ( { model | phoneMode = PMShowDocumentList }, Cmd.none )

        SetDocumentInPhoneAsCurrent permissions doc ->
            let
                ast =
                    Markup.parse doc.language doc.content |> Compiler.Acc.transformST doc.language
            in
            ( { model
                | currentDocument = Just doc
                , sourceText = doc.content
                , initialText = doc.content
                , title = Compiler.ASTTools.title model.language ast
                , tableOfContents = Compiler.ASTTools.tableOfContents ast
                , message = "id = " ++ doc.id
                , permissions = setPermissions model.currentUser permissions doc
                , counter = model.counter + 1
                , phoneMode = PMShowDocument
              }
            , View.Utility.setViewPortToTop
            )

        SetAppMode appMode ->
            ( { model | appMode = appMode }, Cmd.none )

        GotNewWindowDimensions w h ->
            ( { model | windowWidth = w, windowHeight = h }, Cmd.none )

        GotViewport vp ->
            Frontend.Update.updateWithViewport vp model

        SetViewPortForElement result ->
            case result of
                Ok ( element, viewport ) ->
                    ( { model | message = model.message ++ ", setting viewport" }, View.Utility.setViewPortForSelectedLine element viewport )

                Err _ ->
                    -- TODO: restore error message
                    -- ( { model | message = model.message ++ ", could not set viewport" }, Cmd.none )
                    ( model, Cmd.none )

        InputSearchSource str ->
            ( { model | searchSourceText = str, foundIdIndex = 0 }, Cmd.none )

        GetSelection str ->
            ( { model | message = "Selection: " ++ str }, Cmd.none )

        -- SYNC
        SelectedText str ->
            firstSyncLR model str

        SendSyncLR ->
            ( { model | syncRequestIndex = model.syncRequestIndex + 1 }, Cmd.none )

        SyncLR ->
            let
                data =
                    if model.foundIdIndex == 0 then
                        let
                            foundIds_ =
                                Compiler.ASTTools.matchingIdsInAST model.searchSourceText model.editRecord.parsed

                            id_ =
                                List.head foundIds_ |> Maybe.withDefault "(nothing)"
                        in
                        { foundIds = foundIds_
                        , foundIdIndex = 1
                        , cmd = View.Utility.setViewportForElement id_
                        , selectedId = id_
                        , searchCount = 0
                        }

                    else
                        let
                            id_ =
                                List.Extra.getAt model.foundIdIndex model.foundIds |> Maybe.withDefault "(nothing)"
                        in
                        { foundIds = model.foundIds
                        , foundIdIndex = modBy (List.length model.foundIds) (model.foundIdIndex + 1)
                        , cmd = View.Utility.setViewportForElement id_
                        , selectedId = id_
                        , searchCount = model.searchCount + 1
                        }
            in
            ( { model
                | selectedId = data.selectedId
                , foundIds = data.foundIds
                , foundIdIndex = data.foundIdIndex
                , searchCount = data.searchCount
                , message = ("!![" ++ adjustId data.selectedId ++ "]") :: List.map adjustId data.foundIds |> String.join ", "
              }
            , data.cmd
            )

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
            let
                mewLang =
                    case model.language of
                        MicroLaTeXLang ->
                            L0Lang

                        L0Lang ->
                            MicroLaTeXLang
            in
            ( { model | language = mewLang }, Cmd.none )

        Render msg_ ->
            case msg_ of
                Render.Msg.SendMeta _ ->
                    -- ( { model | lineNumber = m.loc.begin.row, message = "line " ++ String.fromInt (m.loc.begin.row + 1) }, Cmd.none )
                    ( model, Cmd.none )

                Render.Msg.SendId line ->
                    -- TODO: the below (using id also for line number) is not a great idea.
                    ( { model | message = "Line " ++ (line |> String.toInt |> Maybe.withDefault 0 |> (\x -> x + 2) |> String.fromInt), linenumber = String.toInt line |> Maybe.withDefault 0 }, Cmd.none )

                Render.Msg.SelectId id ->
                    -- the element with this id will be highlighted
                    ( { model | selectedId = id }, Cmd.none )

                GetPublicDocument id ->
                    ( model, sendToBackend (FetchDocumentById id) )

        Fetch id ->
            ( model, sendToBackend (FetchDocumentById id) )

        DebounceMsg msg_ ->
            let
                ( debounce, cmd ) =
                    Debounce.update
                        debounceConfig
                        (Debounce.takeLast save)
                        msg_
                        model.debounce
            in
            ( { model | debounce = debounce }
            , cmd
            )

        Saved str ->
            updateDoc model str

        Search ->
            ( model, sendToBackend (SearchForDocuments (model.currentUser |> Maybe.map .username) model.inputSearchKey) )

        SearchText ->
            let
                ids =
                    Compiler.ASTTools.matchingIdsInAST model.searchSourceText model.editRecord.parsed

                ( cmd, id ) =
                    case List.head ids of
                        Nothing ->
                            ( Cmd.none, "(none)" )

                        Just id_ ->
                            ( View.Utility.setViewportForElement id_, id_ )
            in
            ( { model | selectedId = id, searchCount = model.searchCount + 1, message = "ids: " ++ String.join ", " ids }, cmd )

        -- ( model, Cmd.none )
        InputText str ->
            let
                -- Push your values here.
                ( debounce, cmd ) =
                    Debounce.push debounceConfig str model.debounce
            in
            let
                editRecord =
                    Compiler.DifferentialParser.update model.editRecord str

                messages : List String
                messages =
                    L0.getMessages
                        editRecord.parsed
            in
            ( { model
                | sourceText = str
                , editRecord = editRecord
                , title = Compiler.ASTTools.title model.language editRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
                , message = String.join ", " messages
                , debounce = debounce
                , counter = model.counter + 1
              }
            , cmd
            )

        SetInitialEditorContent ->
            case model.currentDocument of
                Nothing ->
                    ( { model | message = "Could not set editor content: there is no current document" }, Cmd.none )

                Just doc ->
                    ( { model | initialText = doc.content }, Cmd.none )

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
            case model.currentDocument of
                Nothing ->
                    ( model, Cmd.none )

                Just doc ->
                    ( { model
                        | currentDocument = Just Docs.deleted
                        , documents = List.filter (\d -> d.id /= doc.id) model.documents
                        , deleteDocumentState = WaitingForDeleteAction
                      }
                    , Cmd.batch [ sendToBackend (DeleteDocumentBE doc), Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById Config.documentDeletedNotice)) ]
                    )

        SetPublicDocumentAsCurrentById id ->
            case List.filter (\doc -> doc.id == id) model.publicDocuments |> List.head of
                Nothing ->
                    ( { model | message = "No document of id " ++ id ++ " found" }, Cmd.none )

                Just doc ->
                    let
                        newEditRecord =
                            Compiler.DifferentialParser.init doc.language doc.content
                    in
                    ( { model
                        | currentDocument = Just doc
                        , sourceText = doc.content
                        , initialText = doc.content
                        , editRecord = newEditRecord
                        , title = Compiler.ASTTools.title model.language newEditRecord.parsed
                        , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
                        , message = "id = " ++ doc.id
                        , counter = model.counter + 1
                      }
                    , Cmd.batch [ View.Utility.setViewPortToTop ]
                    )

        SetDocumentAsCurrent permissions doc ->
            let
                newEditRecord =
                    Compiler.DifferentialParser.init doc.language doc.content
            in
            ( { model
                | currentDocument = Just doc
                , sourceText = doc.content
                , initialText = doc.content
                , editRecord = newEditRecord
                , title =
                    Compiler.ASTTools.title model.language newEditRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
                , message = "id = " ++ doc.id
                , permissions = setPermissions model.currentUser permissions doc
                , counter = model.counter + 1
                , language = doc.language
              }
            , Cmd.batch [ View.Utility.setViewPortToTop ]
            )

        SetPublic doc public ->
            let
                newDocument =
                    { doc | public = public }

                documents =
                    List.Extra.setIf (\d -> d.id == newDocument.id) newDocument model.documents
            in
            ( { model | documents = documents, currentDocument = Just newDocument }, sendToBackend (SaveDocument model.currentUser newDocument) )

        SetSortMode sortMode ->
            ( { model | sortMode = sortMode }, Cmd.none )

        ExportToMarkdown ->
            let
                markdownText =
                    -- TODO:implement this
                    -- L1.Render.Markdown.transformDocument model.currentDocument.content
                    "Not implemented"

                fileName_ =
                    "foo" |> String.replace " " "-" |> String.toLower |> (\name -> name ++ ".md")
            in
            ( model, Download.string fileName_ "text/markdown" markdownText )

        ExportToLaTeX ->
            let
                textToExport =
                    LaTeX.export Settings.defaultSettings model.editRecord.parsed

                fileName =
                    (model.currentDocument |> Maybe.map .title |> Maybe.withDefault "doc") ++ ".tex"
            in
            ( model, Download.string fileName "application/x-latex" textToExport )

        Export ->
            issueCommandIfDefined model.currentDocument model exportDoc

        --let
        --    fileName =
        --        "doc" |> String.replace " " "-" |> String.toLower |> (\name -> name ++ ".l1")
        --in
        --( model, Download.string fileName "text/plain" model.currentDocument.content )
        PrintToPDF ->
            PDF.print model

        GotPdfLink result ->
            PDF.gotLink model result

        ChangePrintingState printingState ->
            -- TODO: review this
            issueCommandIfDefined model.currentDocument { model | printingState = printingState } (changePrintingState printingState)

        FinallyDoCleanPrintArtefacts _ ->
            ( model, Cmd.none )

        StartSync ->
            ( { model | doSync = not model.doSync }, Cmd.none )

        NextSync ->
            nextSyncLR model


adjustId : String -> String
adjustId str =
    case String.toInt str of
        Nothing ->
            str

        Just n ->
            String.fromInt (n + 2)


firstSyncLR model searchSourceText =
    let
        data =
            let
                foundIds_ =
                    Compiler.ASTTools.matchingIdsInAST searchSourceText model.editRecord.parsed

                id_ =
                    List.head foundIds_ |> Maybe.withDefault "(nothing)"
            in
            { foundIds = foundIds_
            , foundIdIndex = 1
            , cmd = View.Utility.setViewportForElement id_
            , selectedId = id_
            , searchCount = 0
            }
    in
    ( { model
        | selectedId = data.selectedId
        , foundIds = data.foundIds
        , foundIdIndex = data.foundIdIndex
        , searchCount = data.searchCount
        , message = ("[" ++ adjustId data.selectedId ++ "]") :: List.map adjustId data.foundIds |> String.join ", "
      }
    , data.cmd
    )


nextSyncLR model =
    let
        id_ =
            List.Extra.getAt model.foundIdIndex model.foundIds |> Maybe.withDefault "(nothing)"
    in
    ( { model
        | selectedId = id_
        , foundIdIndex = modBy (List.length model.foundIds) (model.foundIdIndex + 1)
        , searchCount = model.searchCount + 1
        , message = ("[" ++ adjustId id_ ++ "]") :: List.map adjustId model.foundIds |> String.join ", "
      }
    , View.Utility.setViewportForElement id_
    )


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


setPermissions currentUser permissions document =
    case document.author of
        Nothing ->
            permissions

        Just author ->
            if Just author == Maybe.map .username currentUser then
                CanEdit

            else
                permissions


save : String -> Cmd FrontendMsg
save s =
    Task.perform Saved (Task.succeed s)


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
                        Compiler.ASTTools.title model.language model.editRecord.parsed

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
        NoOpToFrontend ->
            ( model, Cmd.none )

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
            in
            ( { model
                | editRecord = editRecord
                , title = Compiler.ASTTools.title model.language editRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
                , showEditor = showEditor
                , currentDocument = Just doc
                , sourceText = doc.content
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
