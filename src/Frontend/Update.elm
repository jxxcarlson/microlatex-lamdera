port module Frontend.Update exposing
    ( addDocToCurrentUser
    , adjustId
    , changeLanguage
    , changeSlug
    , closeEditor
    , debounceMsg
    , exportToLaTeX
    , exportToMarkdown
    , exportToRawLaTeX
    , firstSyncLR
    , handleAsReceivedDocumentWithDelay
    , handleAsStandardReceivedDocument
    , handleCurrentDocumentChange
    , handleKeepingMasterDocument
    , handlePinnedDocuments
    , handleReceivedDocumentAsManual
    , handleSharedDocument
    , handleUrlRequest
    , hardDeleteDocument
    , inputCursor
    , inputText
    , inputTitle
    , newDocument
    , newFolder
    , nextSyncLR
    , openEditor
    , playSound
    , postProcessDocument
    , prepareMasterDocument
    , render
    , runSpecial
    , saveCurrentDocumentToBackend
    , saveDocumentToBackend
    , searchText
    , setDocumentAsCurrent
    , setDocumentInPhoneAsCurrent
    , setInitialEditorContent
    , setLanguage
    , setPublic
    , setPublicDocumentAsCurrentById
    , setUserLanguage
    , setViewportForElement
    , signIn
    , signOut
    , signUp
    , softDeleteDocument
    , syncLR
    , undeleteDocument
    , updateDoc
    , updateEditRecord
    , updateKeys
    , updateWithViewport
    )

--

import Authentication
import BoundedDeque exposing (BoundedDeque)
import Browser
import CollaborativeEditing.NetworkModel as NetworkModel
import Compiler.ASTTools
import Compiler.Acc
import Compiler.DifferentialParser
import Config
import Debounce
import Dict exposing (Dict)
import Docs
import Document exposing (Document)
import Duration
import Effect.Browser.Dom
import Effect.Browser.Navigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File.Download
import Effect.Lamdera exposing (sendToBackend)
import Effect.Process
import Effect.Task
import Effect.Time
import ExtractInfo
import Frontend.Cmd
import IncludeFiles
import Keyboard
import List.Extra
import Markup
import Message
import Parser.Language exposing (Language(..))
import Predicate
import Render.Export.LaTeX
import Render.Markup
import Render.Msg exposing (Handling(..), MarkupMsg(..), SolutionState(..))
import Render.Settings as Settings
import Types exposing (DocumentDeleteState(..), DocumentHandling(..), DocumentList(..), FrontendModel, FrontendMsg(..), MessageStatus(..), PhoneMode(..), PopupState(..), ToBackend(..))
import User exposing (User)
import Util
import View.Utility


port playSound : String -> Cmd msg



-- port playSound : String -> Command FrontendOnly ToBackend FrontendMsg
{-
         --- CONTENTS

   --- SIGN UP, SIGN IN, SIGN OUT
   --- EDITOR
   --- EXPORT
   --- DOCUMENT
   ---    Save
   ---    Set params
   ---    Post process
   ---    setDocumentAsCurrent
   ---    handleCurrentDocumentChange
   ---    Included files
   ---    updateDoc
   ---    handle document
   ---    savePreviousCurrentDocumentCmd
   ---    delete
   --- SEARCH
   --- INPUT
   --- DEBOUNCE
   --- RENDER
   --- SET PARAM
   --- SYNC
   --- VIEWPORT
   --- SPECIAL
   --- URL HANDLING
   --- KEYBOARD COMMANDS
   --- UTILITY


-}
--- SIGN UP, SIGN IN, SIGN OUT


signOut : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
signOut model =
    let
        cmd =
            case model.currentUser of
                Nothing ->
                    Command.none

                Just user ->
                    Effect.Lamdera.sendToBackend (UpdateUserWith user)
    in
    ( { model
        | currentUser = Nothing
        , activeEditor = Nothing
        , clientIds = []
        , currentDocument = Just Docs.simpleWelcomeDoc
        , currentMasterDocument = Nothing
        , documents = []
        , messages = [ { txt = "Signed out", status = MSWhite } ]
        , inputSearchKey = ""
        , actualSearchKey = ""
        , inputTitle = ""
        , chatMessages = []
        , tagSelection = Types.TagPublic
        , inputUsername = ""
        , inputPassword = ""
        , documentList = StandardList
        , maximizedIndex = Types.MPublicDocs
        , popupState = NoPopup
        , showEditor = False
        , chatVisible = False
        , sortMode = Types.SortByMostRecent
        , lastInteractionTime = Effect.Time.millisToPosix 0
      }
    , Command.batch
        [ Effect.Browser.Navigation.pushUrl model.key "/"
        , cmd
        , Effect.Lamdera.sendToBackend (SignOutBE (model.currentUser |> Maybe.map .username))
        , Effect.Lamdera.sendToBackend (GetDocumentById Types.StandardHandling Config.welcomeDocId)
        , Effect.Lamdera.sendToBackend (GetPublicDocuments Types.SortByMostRecent Nothing)
        ]
    )



-- |> join (unshare (User.currentUsername model.currentUser))
-- narrowCast : Username -> Document.Document -> Types.ConnectionDict -> Cmd Types.BackendMsg
--     , Cmd.batch (narrowCastDocs model username documents)


signIn : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
signIn model =
    if String.length model.inputPassword >= 8 then
        case Config.defaultUrl of
            Nothing ->
                ( { model | timer = 0, inputPassword = "", showSignInTimer = True }, Effect.Lamdera.sendToBackend (SignInBE model.inputUsername (Authentication.encryptForTransit model.inputPassword)) )

            Just url ->
                ( { model | timer = 0, inputPassword = "", showSignInTimer = True, url = url }, Effect.Lamdera.sendToBackend (SignInBE model.inputUsername (Authentication.encryptForTransit model.inputPassword)) )

    else
        ( { model | inputPassword = "", showSignInTimer = True, messages = [ { txt = "Password must be at least 8 letters long.", status = MSYellow } ] }, Command.none )


signUp : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
signUp model =
    let
        errors =
            []
                |> reject (String.length model.inputSignupUsername < 3) "username: at least three letters"
                |> reject (String.toLower model.inputSignupUsername /= model.inputSignupUsername) "username: all lower case characters"
                |> reject (model.inputPassword == "") "password: cannot be empty"
                |> reject (String.length model.inputPassword < 8) "password: at least 8 letters long."
                |> reject (model.inputPassword /= model.inputPasswordAgain) "passwords do not match"
                |> reject (model.inputEmail == "") "missing email address"
                |> reject (model.inputRealname == "") "missing real name"
    in
    if List.isEmpty errors then
        ( model
        , Effect.Lamdera.sendToBackend (SignUpBE model.inputSignupUsername model.inputLanguage (Authentication.encryptForTransit model.inputPassword) model.inputRealname model.inputEmail)
        )

    else
        ( { model | messages = [ { txt = String.join "; " errors, status = MSYellow } ] }, Command.none )



--- EDITOR


addUserToCurrentEditorsOfDocument : Maybe User -> Document -> Document
addUserToCurrentEditorsOfDocument currentUser doc =
    case currentUser of
        Nothing ->
            doc

        Just user ->
            let
                oldEditorList =
                    doc.currentEditorList

                equal a b =
                    a.userId == b.userId

                editorItem : Document.EditorData
                editorItem =
                    -- TODO: need actual clients
                    { userId = user.id, username = user.username, clients = [] }

                currentEditorList =
                    if Predicate.documentIsMineOrSharedToMe (Just doc) currentUser then
                        Util.insertInListOrUpdate equal editorItem oldEditorList

                    else
                        oldEditorList

                updatedDoc =
                    if Predicate.documentIsMineOrSharedToMe (Just doc) currentUser then
                        { doc | status = Document.DSCanEdit, currentEditorList = currentEditorList }

                    else
                        { doc | status = Document.DSReadOnly }
            in
            updatedDoc


{-| }
When the editor is opened, the current user is added to the document's
current editor list. This changed needs to saved to the backend and
narrowcast to the other users who to whom this document is shared,
so that **all** relevant frontends remain in sync. Otherwise there
will be shared set of editors among the various users editing the document.
-}
openEditor : Document -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
openEditor doc model =
    case model.currentUser of
        Nothing ->
            ( model, Command.none )

        Just currentUser ->
            let
                updatedDoc =
                    addUserToCurrentEditorsOfDocument model.currentUser doc

                sendersName =
                    currentUser.username

                sendersId =
                    currentUser.id
            in
            ( { model
                | showEditor = True
                , sourceText = doc.content
                , oTDocument = { docId = doc.id, cursor = 0, content = doc.content }
                , initialText = ""
                , currentDocument = Just updatedDoc
              }
            , Command.batch
                [ Frontend.Cmd.setInitialEditorContent 20
                , if Predicate.documentIsMineOrSharedToMe (Just updatedDoc) model.currentUser then
                    Effect.Lamdera.sendToBackend (AddEditor currentUser updatedDoc)

                  else
                    Command.none
                , if Predicate.shouldNarrowcast model.currentUser (Just updatedDoc) then
                    Effect.Lamdera.sendToBackend (NarrowcastExceptToSender sendersName sendersId updatedDoc)

                  else
                    Command.none
                ]
            )


setInitialEditorContent : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setInitialEditorContent model =
    case model.currentDocument of
        Nothing ->
            ( { model | messages = [ { txt = "Could not set editor content: there is no current document", status = MSWhite } ] }, Command.none )

        Just doc ->
            ( { model | initialText = doc.content }, Command.none )


closeEditor : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
closeEditor model =
    let
        updatedDoc : Maybe Document
        updatedDoc =
            User.mRemoveEditor model.currentUser model.currentDocument
                |> Maybe.map setToReadOnlyIfNoEditors

        saveCmd =
            case updatedDoc of
                Nothing ->
                    Command.none

                Just doc ->
                    Command.batch
                        [ Effect.Lamdera.sendToBackend (SaveDocument model.currentUser doc)
                        , if Predicate.documentIsMineOrSharedToMe updatedDoc model.currentUser then
                            Effect.Lamdera.sendToBackend (NarrowcastExceptToSender (User.currentUsername model.currentUser) (User.currentUserId model.currentUser) doc)

                          else
                            Command.none
                        ]

        documents =
            case updatedDoc of
                Nothing ->
                    model.documents

                Just doc ->
                    Document.updateDocumentInList doc model.documents
    in
    ( { model
        | currentDocument = updatedDoc
        , documents = documents
        , initialText = ""
        , popupState = NoPopup
        , showEditor = False
      }
    , saveCmd
    )


{-|

    From the cursor, content information received from the editor (on cursor or text change),
    compute the editEvent, where it will be sent to the backend, then narrowcast to
    the clients current editing the given shared document.

-}
handleEditorChange : FrontendModel -> Int -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleEditorChange model cursor content =
    let
        --_ =
        --    Debug.log "(cursor, content)" ( cursor, content )
        newOTDocument =
            let
                id =
                    Maybe.map .id model.currentDocument |> Maybe.withDefault "---"
            in
            { docId = id, cursor = cursor, content = content }

        -- |> Debug.log "OT NEW"
        userId =
            model.currentUser |> Maybe.map .id |> Maybe.withDefault "---"

        --oldDocument =
        --model.networkModel.serverState.document |> Debug.log "OT OLD"
        editEvent_ =
            NetworkModel.createEvent userId model.oTDocument newOTDocument

        -- |> Debug.log "OT EVENT"
    in
    ( { model | counter = model.counter + 1, oTDocument = newOTDocument }, Effect.Lamdera.sendToBackend (PushEditorEvent editEvent_) )



--- EXPORT


exportToLaTeX : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
exportToLaTeX model =
    let
        textToExport =
            Render.Export.LaTeX.export Settings.defaultSettings model.editRecord.parsed

        fileName =
            (model.currentDocument
                |> Maybe.map .title
                |> Maybe.withDefault "doc"
                |> String.toLower
                |> Util.compressWhitespace
                |> String.replace " " "-"
            )
                ++ ".tex"
    in
    ( model, Effect.File.Download.string fileName "application/x-latex" textToExport )


exportToRawLaTeX : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
exportToRawLaTeX model =
    let
        textToExport =
            Render.Export.LaTeX.rawExport Settings.defaultSettings model.editRecord.parsed

        fileName =
            (model.currentDocument
                |> Maybe.map .title
                |> Maybe.withDefault "doc"
                |> String.toLower
                |> Util.compressWhitespace
                |> String.replace " " "-"
            )
                ++ ".tex"
    in
    ( model, Effect.File.Download.string fileName "application/x-latex" textToExport )


exportToMarkdown : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
exportToMarkdown model =
    let
        markdownText =
            -- TODO:implement this
            -- L1.Render.Markdown.transformDocument model.currentDocument.content
            "Not implemented"

        fileName_ =
            "foo" |> String.replace " " "-" |> String.toLower |> (\name -> name ++ ".md")
    in
    ( model, Effect.File.Download.string fileName_ "text/markdown" markdownText )



--- DOCUMENT


newFolder : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
newFolder model =
    let
        folderDocument =
            ExtractInfo.makeFolder model.currentTime (model.currentUser |> Maybe.map .username |> Maybe.withDefault "anon") model.inputFolderName model.inputFolderTag

        documentsCreatedCounter =
            model.documentsCreatedCounter + 1

        editRecord =
            Compiler.DifferentialParser.init model.includedContent folderDocument.language folderDocument.content
    in
    ( { model
        | showEditor = False
        , inputTitle = ""
        , title = Compiler.ASTTools.title editRecord.parsed
        , documentsCreatedCounter = documentsCreatedCounter
        , popupState = NoPopup
      }
    , Command.batch [ Effect.Lamdera.sendToBackend (CreateDocument model.currentUser folderDocument) ]
    )


newDocument : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
newDocument model =
    let
        emptyDoc =
            Document.empty

        documentsCreatedCounter =
            model.documentsCreatedCounter + 1

        titleString =
            if String.length model.inputTitle < 3 then
                "??"

            else
                model.inputTitle

        title =
            case model.language of
                MicroLaTeXLang ->
                    "\\title{" ++ titleString ++ "}\n\n"

                _ ->
                    "| title\n" ++ titleString ++ "\n\n"

        doc =
            { emptyDoc
                | title = titleString
                , content = title
                , author = Maybe.map .username model.currentUser
                , language = model.language
            }
                |> Document.addSlug
    in
    ( { model
        | inputTitle = ""
        , counter = model.counter + 1
        , documentsCreatedCounter = documentsCreatedCounter
        , popupState = NoPopup
      }
        |> postProcessDocument doc
    , Command.batch [ Effect.Lamdera.sendToBackend (CreateDocument model.currentUser doc) ]
    )



---    Save


saveDocumentToBackend : Maybe User -> Document.Document -> Command FrontendOnly ToBackend FrontendMsg
saveDocumentToBackend currentUser doc =
    case doc.status of
        Document.DSSoftDelete ->
            Command.none

        Document.DSReadOnly ->
            Command.none

        Document.DSCanEdit ->
            Effect.Lamdera.sendToBackend (SaveDocument currentUser doc)


saveCurrentDocumentToBackend : Maybe Document.Document -> Maybe User -> Command FrontendOnly ToBackend FrontendMsg
saveCurrentDocumentToBackend mDoc mUser =
    case mDoc of
        Nothing ->
            Command.none

        Just doc ->
            case doc.status of
                Document.DSSoftDelete ->
                    Command.none

                Document.DSReadOnly ->
                    Command.none

                Document.DSCanEdit ->
                    Effect.Lamdera.sendToBackend (SaveDocument mUser doc)



---    Set params


setPermissions : Maybe User -> DocumentHandling -> Document -> DocumentHandling
setPermissions currentUser permissions document =
    case document.author of
        Nothing ->
            permissions

        Just author ->
            if Just author == Maybe.map .username currentUser then
                StandardHandling

            else
                permissions


setPublic : FrontendModel -> Document -> Bool -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setPublic model doc public =
    let
        newDocument_ =
            { doc | public = public }

        documents =
            List.Extra.setIf (\d -> d.id == newDocument_.id) newDocument_ model.documents
    in
    ( { model | documents = documents, documentDirty = False, currentDocument = Just newDocument_, inputTitle = "" }, Effect.Lamdera.sendToBackend (SaveDocument model.currentUser newDocument_) )


setPublicDocumentAsCurrentById : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setPublicDocumentAsCurrentById model id =
    case List.filter (\doc -> doc.id == id) model.publicDocuments |> List.head of
        Nothing ->
            ( { model | messages = [ { txt = "No document of id [" ++ id ++ "] found", status = MSWhite } ] }, Command.none )

        Just doc ->
            let
                newEditRecord =
                    Compiler.DifferentialParser.init model.includedContent doc.language doc.content
            in
            ( { model
                | currentDocument = Just doc
                , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (User.currentUserId model.currentUser) doc.content)
                , sourceText = doc.content
                , initialText = doc.content
                , editRecord = newEditRecord
                , title = Compiler.ASTTools.title newEditRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
                , messages = [ { txt = "id = " ++ doc.id, status = MSWhite } ]
                , counter = model.counter + 1
              }
            , Command.batch [ View.Utility.setViewPortToTop model.popupState ]
            )



---    Post process


postProcessDocument : Document.Document -> FrontendModel -> FrontendModel
postProcessDocument doc model =
    let
        newEditRecord : Compiler.DifferentialParser.EditRecord
        newEditRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        errorMessages : List Types.Message
        errorMessages =
            Message.make (newEditRecord.messages |> String.join "; ") MSYellow

        ( readers, editors ) =
            View.Utility.getReadersAndEditors (Just doc)
    in
    { model
        | currentDocument = Just doc
        , sourceText = doc.content
        , initialText = doc.content
        , editRecord = newEditRecord
        , title =
            Compiler.ASTTools.title newEditRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
        , counter = model.counter + 1
        , language = doc.language
        , inputReaders = readers
        , messages = errorMessages
        , inputEditors = editors
    }


setDocumentInPhoneAsCurrent : FrontendModel -> Document -> DocumentHandling -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setDocumentInPhoneAsCurrent model doc permissions =
    let
        ast =
            Markup.parse doc.language doc.content |> Compiler.Acc.transformST doc.language
    in
    ( { model
        | currentDocument = Just doc
        , sourceText = doc.content
        , initialText = doc.content
        , title = Compiler.ASTTools.title ast
        , tableOfContents = Compiler.ASTTools.tableOfContents ast
        , messages = [ { txt = "id = " ++ doc.id, status = MSWhite } ]
        , permissions = setPermissions model.currentUser permissions doc
        , counter = model.counter + 1
        , phoneMode = PMShowDocument
      }
    , View.Utility.setViewPortToTop model.popupState
    )



---    setDocumentAsCurrent


setDocumentAsCurrent : Command FrontendOnly ToBackend FrontendMsg -> FrontendModel -> Document.Document -> DocumentHandling -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setDocumentAsCurrent cmd model doc permissions =
    -- TODO: A
    let
        filesToInclude =
            IncludeFiles.getData doc.content

        oldCurrentDocument =
            model.currentDocument
                |> User.mRemoveEditor model.currentUser
                |> Maybe.map setToReadOnlyIfNoEditors

        ( updateOldCurrentDocCmd, newModel ) =
            case oldCurrentDocument of
                Nothing ->
                    ( Command.none, model )

                Just oldCurrentDoc_ ->
                    ( sendToBackend (SaveDocument model.currentUser oldCurrentDoc_), { model | documents = Document.updateDocumentInList oldCurrentDoc_ model.documents } )
    in
    case List.isEmpty filesToInclude of
        True ->
            setDocumentAsCurrent_ (Command.batch [ updateOldCurrentDocCmd ]) newModel doc permissions

        False ->
            setDocumentAsCurrent_ (Command.batch [ updateOldCurrentDocCmd, cmd, Effect.Lamdera.sendToBackend (GetIncludedFiles doc filesToInclude) ]) newModel doc permissions


setToReadOnlyIfNoEditors : Document -> Document
setToReadOnlyIfNoEditors doc =
    if doc.currentEditorList == [] then
        { doc | status = Document.DSReadOnly }

    else
        doc


setDocumentAsCurrent_ : Command FrontendOnly ToBackend FrontendMsg -> FrontendModel -> Document.Document -> DocumentHandling -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setDocumentAsCurrent_ cmd model doc permissions =
    case model.currentUser of
        Nothing ->
            let
                newModel =
                    postProcessDocument doc model
            in
            ( { newModel | currentDocument = Just doc }, Command.none )

        Just currentUser ->
            let
                -- For now, loc the doc in all cases
                currentUserName_ =
                    currentUser.username

                smartDocCommand =
                    makeSmartDocCommand doc model.allowOpenFolder currentUserName_

                --    Compiler.DifferentialParser.init model.includedContent doc.language doc.content
                errorMessages : List Types.Message
                errorMessages =
                    Message.make (newEditRecord.messages |> String.join "; ") MSYellow

                ( currentMasterDocument, newEditRecord, getFirstDocumentCommand ) =
                    prepareMasterDocument model doc

                ( readers, editors ) =
                    View.Utility.getReadersAndEditors (Just doc)

                newCurrentUser =
                    addDocToCurrentUser model doc

                newDocumentStatus =
                    if doc.status == Document.DSSoftDelete then
                        Document.DSSoftDelete

                    else if Predicate.documentIsMineOrSharedToMe (Just doc) model.currentUser && model.showEditor then
                        Document.DSCanEdit

                    else
                        Document.DSReadOnly

                updatedDoc =
                    { doc | status = newDocumentStatus }
                        |> Util.applyIf model.showEditor (addUserToCurrentEditorsOfDocument model.currentUser)
            in
            ( { model
                | currentDocument = Just updatedDoc
                , oTDocument = { docId = updatedDoc.id, cursor = 0, content = updatedDoc.content }
                , selectedSlug = Document.getSlug updatedDoc
                , currentMasterDocument = currentMasterDocument
                , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (User.currentUserId model.currentUser) doc.content)
                , sourceText = doc.content
                , initialText = doc.content
                , documents = Document.updateDocumentInList updatedDoc model.documents
                , editRecord = newEditRecord
                , title =
                    Compiler.ASTTools.title newEditRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
                , permissions = setPermissions model.currentUser permissions doc
                , counter = model.counter + 1
                , language = doc.language
                , currentUser = newCurrentUser
                , inputReaders = readers
                , inputEditors = editors
                , messages = errorMessages
                , lastInteractionTime = model.currentTime
              }
            , Command.batch
                [ View.Utility.setViewPortToTop model.popupState
                , Command.batch [ getFirstDocumentCommand, cmd, Effect.Lamdera.sendToBackend (SaveDocument model.currentUser updatedDoc) ]
                , Effect.Browser.Navigation.pushUrl model.key ("/c/" ++ doc.id)
                , smartDocCommand
                ]
            )


makeSmartDocCommand : Document -> Bool -> String -> Command FrontendOnly ToBackend FrontendMsg
makeSmartDocCommand doc allowOpenFolder currentUserName_ =
    case ExtractInfo.parseInfo "type" doc.content of
        Nothing ->
            Command.none

        Just ( label, dict ) ->
            if label == "folder" && allowOpenFolder then
                case Dict.get "get" dict of
                    Nothing ->
                        Command.none

                    Just tag ->
                        sendToBackend (MakeCollection doc.title currentUserName_ ("folder:" ++ tag))

            else
                Command.none


prepareMasterDocument : FrontendModel -> Document -> ( Maybe Document, Compiler.DifferentialParser.EditRecord, Command FrontendOnly ToBackend FrontendMsg )
prepareMasterDocument model doc =
    let
        newEditRecord : Compiler.DifferentialParser.EditRecord
        newEditRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content
    in
    if Predicate.isMaster newEditRecord && model.allowOpenFolder then
        let
            maybeFirstDocId =
                ExtractInfo.parseBlockNameWithArgs "document" doc.content
                    |> Maybe.map Tuple.second
                    |> Maybe.andThen List.head
        in
        case maybeFirstDocId of
            Nothing ->
                ( Nothing, newEditRecord, Command.none )

            Just id ->
                ( Just doc, newEditRecord, sendToBackend (FetchDocumentById (KeepMasterDocument doc) id) )

    else
        ( Nothing, newEditRecord, Command.none )



---    handleCurrentDocumentChange


handleCurrentDocumentChange : FrontendModel -> Document -> Document -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleCurrentDocumentChange model currentDocument document =
    if model.documentDirty && currentDocument.status == Document.DSCanEdit then
        -- we are leaving the old current document.
        -- make sure that the content is saved and its status is set to read only
        let
            updatedDoc =
                { currentDocument | content = model.sourceText, status = Document.DSReadOnly }

            newModel =
                { model
                    | documentDirty = False
                    , language = document.language
                    , selectedSlug = Document.getSlug currentDocument
                    , documents = Document.updateDocumentInList updatedDoc model.documents
                }
        in
        setDocumentAsCurrent (Effect.Lamdera.sendToBackend (SaveDocument model.currentUser updatedDoc)) newModel document StandardHandling

    else if currentDocument.status == Document.DSCanEdit then
        let
            updatedDoc =
                { currentDocument | status = Document.DSReadOnly }

            newModel =
                { model | selectedSlug = Document.getSlug currentDocument, documents = Document.updateDocumentInList updatedDoc model.documents, language = document.language }
        in
        setDocumentAsCurrent (Effect.Lamdera.sendToBackend (SaveDocument model.currentUser updatedDoc)) newModel document StandardHandling

    else
        setDocumentAsCurrent Command.none model document StandardHandling



---    Included files
---    updateDoc


updateDoc : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateDoc model str =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            case doc.status of
                Document.DSSoftDelete ->
                    ( model, Command.none )

                Document.DSReadOnly ->
                    ( { model | messages = [ { txt = "Document is read-only (can't save edits)", status = MSRed } ] }, Command.none )

                Document.DSCanEdit ->
                    -- if Share.canEdit model.currentUser (Just doc) then
                    -- if View.Utility.canSaveStrict model.currentUser doc then
                    -- if Document.numberOfEditors (Just doc) < 2 && doc.handling == Document.DHStandard then
                    let
                        activeEditorName =
                            model.activeEditor |> Maybe.map .name
                    in
                    if Predicate.documentIsMineOrSharedToMe (Just doc) model.currentUser then
                        if activeEditorName == Nothing || activeEditorName == Maybe.map .username model.currentUser then
                            updateDoc_ doc str model

                        else
                            ( model, Command.none )

                    else
                        ( model, Command.none )


updateDoc_ : Document.Document -> String -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
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

        newDocument_ =
            { doc | content = safeContent, title = safeTitle }

        documents =
            Document.updateDocumentInList newDocument_ model.documents

        publicDocuments =
            if newDocument_.public then
                Document.updateDocumentInList newDocument_ model.publicDocuments

            else
                model.publicDocuments

        sendersName =
            User.currentUsername model.currentUser

        sendersId =
            User.currentUserId model.currentUser
    in
    ( { model
        | currentDocument = Just newDocument_
        , counter = model.counter + 1
        , documents = documents
        , documentDirty = False
        , publicDocuments = publicDocuments
        , currentUser = addDocToCurrentUser model doc
      }
    , Command.batch
        [ saveDocumentToBackend model.currentUser newDocument_
        , if Predicate.shouldNarrowcast model.currentUser (Just newDocument_) then
            Effect.Lamdera.sendToBackend (NarrowcastExceptToSender sendersName sendersId newDocument_)

          else
            Command.none
        ]
    )


changeSlug : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
changeSlug model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                newDocument_ =
                    Document.changeSlug doc
            in
            ( { model | currentDocument = Just newDocument_ } |> postProcessDocument newDocument_
            , sendToBackend (SaveDocument model.currentUser newDocument_)
            )


updateEditRecord : Dict String String -> Document -> FrontendModel -> FrontendModel
updateEditRecord inclusionData doc model =
    { model | editRecord = Compiler.DifferentialParser.init inclusionData doc.language doc.content }



---    handle document


handleReceivedDocumentAsManual : FrontendModel -> Document -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleReceivedDocumentAsManual model doc =
    ( { model
        | currentManual = Just doc
        , counter = model.counter + 1
        , messages =
            { txt = "Manual: " ++ doc.title, status = MSGreen } :: []
      }
    , View.Utility.setViewPortToTop model.popupState
    )



-- TODO: B


handleAsStandardReceivedDocument : FrontendModel -> Document -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleAsStandardReceivedDocument model doc =
    let
        maybeFirstDocId =
            ExtractInfo.parseBlockNameWithArgs "document" doc.content
                |> Maybe.map Tuple.second
                |> Maybe.andThen List.head

        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        -- TODO: fix this
        -- errorMessages : List Types.Message
        currentMasterDocument =
            if Predicate.isMaster editRecord then
                Just doc

            else
                model.currentMasterDocument

        smartDocCommand =
            makeSmartDocCommand doc model.allowOpenFolder (model.currentUser |> Maybe.map .username |> Maybe.withDefault "---")
    in
    case maybeFirstDocId of
        Nothing ->
            ( { model
                | editRecord = editRecord
                , selectedSlug = Document.getSlug doc
                , title = Compiler.ASTTools.title editRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
                , documents = Document.updateDocumentInList doc model.documents -- insertInListOrUpdate
                , currentDocument = Just doc
                , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (User.currentUserId model.currentUser) doc.content)
                , sourceText = doc.content
                , messages = { txt = "Received (std): " ++ doc.title, status = MSGreen } :: []
                , currentMasterDocument = currentMasterDocument
                , counter = model.counter + 1
              }
            , Command.batch
                [ savePreviousCurrentDocumentCmd model
                , Frontend.Cmd.setInitialEditorContent 20
                , View.Utility.setViewPortToTop model.popupState
                , Effect.Browser.Navigation.pushUrl model.key ("/c/" ++ doc.id)
                , smartDocCommand
                ]
            )

        Just id ->
            ( model, Command.batch [ sendToBackend (FetchDocumentById (KeepMasterDocument doc) id), smartDocCommand ] )


handleKeepingMasterDocument : FrontendModel -> Document -> Document -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleKeepingMasterDocument model masterDoc doc =
    let
        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content
    in
    ( { model
        | editRecord = editRecord
        , selectedSlug = Document.getSlug doc
        , title = Compiler.ASTTools.title editRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
        , documents = Document.updateDocumentInList doc model.documents -- insertInListOrUpdate
        , currentDocument = Just doc
        , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (User.currentUserId model.currentUser) doc.content)
        , sourceText = doc.content
        , initialText = doc.content
        , messages = { txt = "Received (std): " ++ doc.title, status = MSGreen } :: []
        , currentMasterDocument = Just masterDoc
        , counter = model.counter + 1
      }
    , Command.batch
        [ savePreviousCurrentDocumentCmd model
        , Frontend.Cmd.setInitialEditorContent 20
        , View.Utility.setViewPortToTop model.popupState
        , Effect.Browser.Navigation.pushUrl model.key ("/c/" ++ doc.id)
        ]
    )


handleSharedDocument : FrontendModel -> String -> Document -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleSharedDocument model username doc =
    let
        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        -- errorMessages : List Types.Message
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
        , documents = Document.updateDocumentInList doc model.documents -- insertInListOrUpdate
        , currentDocument = Just doc
        , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (User.currentUserId model.currentUser) doc.content)
        , sourceText = doc.content
        , activeEditor = Just { name = username, activeAt = model.currentTime }
        , messages = { txt = "Received (shared): " ++ doc.title, status = MSYellow } :: []
        , currentMasterDocument = currentMasterDocument
        , counter = model.counter + 1
      }
    , Command.batch
        [ Effect.Browser.Navigation.pushUrl model.key ("/c/" ++ doc.id)
        , savePreviousCurrentDocumentCmd model
        , Frontend.Cmd.setInitialEditorContent 20

        -- , View.Utility.setViewPortToTop model.popupState
        ]
    )


handleAsReceivedDocumentWithDelay : FrontendModel -> Document -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleAsReceivedDocumentWithDelay model doc =
    let
        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        errorMessages : List Types.Message
        errorMessages =
            Message.make (editRecord.messages |> String.join "; ") MSYellow

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
        , documents = Document.updateDocumentInList doc model.documents -- insertInListOrUpdate
        , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (User.currentUserId model.currentUser) doc.content)
        , currentDocument = Just doc
        , sourceText = doc.content
        , messages = errorMessages
        , currentMasterDocument = currentMasterDocument
        , counter = model.counter + 1
      }
    , Command.batch
        [ Effect.Browser.Navigation.pushUrl model.key ("/c/" ++ doc.id)
        , Util.delay 200 (SetDocumentCurrent doc)
        , Frontend.Cmd.setInitialEditorContent 20
        , View.Utility.setViewPortToTop model.popupState
        ]
    )


handlePinnedDocuments : FrontendModel -> Document -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handlePinnedDocuments model doc =
    let
        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        errorMessages : List Types.Message
        errorMessages =
            Message.make (editRecord.messages |> String.join "; ") MSYellow

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
        , documents = Document.updateDocumentInList doc model.documents -- insertInListOrUpdate
        , currentDocument = Just doc
        , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (User.currentUserId model.currentUser) doc.content)
        , sourceText = doc.content
        , messages = errorMessages
        , currentMasterDocument = currentMasterDocument
        , counter = model.counter + 1
      }
    , Command.batch
        [ Effect.Browser.Navigation.pushUrl model.key ("/c/" ++ doc.id)
        , Frontend.Cmd.setInitialEditorContent 20
        , View.Utility.setViewPortToTop model.popupState
        ]
    )



---    savePreviousCurrentDocumentCmd


{-| Use this function to ensure that edits to the current document are saved
before the current document is changed
-}
savePreviousCurrentDocumentCmd : FrontendModel -> Command FrontendOnly ToBackend FrontendMsg
savePreviousCurrentDocumentCmd model =
    case model.currentDocument of
        Nothing ->
            Command.none

        Just previousDoc ->
            if model.documentDirty && previousDoc.status == Document.DSCanEdit then
                let
                    previousDoc2 =
                        -- TODO: change content
                        { previousDoc | content = model.sourceText }
                in
                Effect.Lamdera.sendToBackend (SaveDocument model.currentUser previousDoc2)

            else
                Command.none



---    delete


undeleteDocument : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
undeleteDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                updatedUser : Maybe User
                updatedUser =
                    case model.currentUser of
                        Nothing ->
                            Nothing

                        Just user ->
                            Just user

                -- deleteDocFromCurrentUser model doc
                ( newDoc, currentDocument, newDocuments ) =
                    let
                        newDoc_ =
                            { doc | status = Document.DSCanEdit } |> Document.removeTag "folder:deleted"
                    in
                    ( newDoc_, Just Docs.deleted, newDoc_ :: List.filter (\doc_ -> doc_.id /= doc.id) model.documents )
            in
            ( { model
                | currentDocument = currentDocument
                , documents = newDocuments
                , documentDirty = False
                , deleteDocumentState = WaitingForDeleteAction
                , currentUser = updatedUser
              }
                |> postProcessDocument newDoc
            , Command.batch
                [ Effect.Lamdera.sendToBackend (SaveDocument model.currentUser newDoc)

                --, Effect.Process.sleep (Duration.milliseconds 500) |> Effect.Task.perform (always (SetPublicDocumentAsCurrentById Config.documentDeletedNotice))
                ]
            )


softDeleteDocument : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
softDeleteDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                updatedUser =
                    case model.currentUser of
                        Nothing ->
                            Nothing

                        Just _ ->
                            deleteDocFromCurrentUser model doc

                ( newDoc, currentDocument, newDocuments ) =
                    ( { doc | status = Document.DSSoftDelete } |> Document.addTag "folder:deleted", Just Docs.deleted, List.filter (\d -> d.id /= doc.id) model.documents )
            in
            ( { model
                | currentDocument = currentDocument
                , documents = newDocuments
                , documentDirty = False
                , deleteDocumentState = WaitingForDeleteAction
                , currentUser = updatedUser
              }
                |> postProcessDocument Docs.deleted
            , Command.batch
                [ Effect.Lamdera.sendToBackend (SaveDocument model.currentUser newDoc)
                ]
            )


hardDeleteDocument : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
hardDeleteDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                newUser =
                    case model.currentUser of
                        Nothing ->
                            Nothing

                        Just _ ->
                            deleteDocFromCurrentUser model doc

                newMasterDocument =
                    case model.currentMasterDocument of
                        Nothing ->
                            Nothing

                        Just masterDoc ->
                            let
                                newContent =
                                    masterDoc.content
                                        |> String.lines
                                        |> List.filter (\line -> not (String.contains doc.title line || String.contains doc.id line))
                                        |> String.join "\n"
                            in
                            Just { masterDoc | content = newContent }
            in
            ( { model
                | currentDocument = Just Docs.deleted
                , currentMasterDocument = newMasterDocument
                , documents = List.filter (\d -> d.id /= doc.id) model.documents
                , hardDeleteDocumentState = Types.WaitingForHardDeleteAction
                , currentUser = newUser
              }
                |> postProcessDocument Docs.deleted
            , Command.batch [ Effect.Lamdera.sendToBackend (HardDeleteDocumentBE doc), Effect.Process.sleep (Duration.milliseconds 500) |> Effect.Task.perform (always (SetPublicDocumentAsCurrentById Config.documentDeletedNotice)) ]
            )



--- SEARCH


searchText : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
searchText model =
    let
        ids =
            Compiler.ASTTools.matchingIdsInAST model.searchSourceText model.editRecord.parsed

        ( cmd, id ) =
            case List.head ids of
                Nothing ->
                    ( Command.none, "(none)" )

                Just id_ ->
                    ( View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_, id_ )
    in
    ( { model | selectedId = id, searchCount = model.searchCount + 1, messages = [ { txt = "ids: " ++ String.join ", " ids, status = MSWhite } ] }, cmd )



--- INPUT


inputTitle : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
inputTitle model str =
    ( { model | inputTitle = str }, Command.none )



-- INPUT FROM THE CODEMIRROR EDITOR (CHANGES IN CURSOR, TEXT)


inputCursor : { position : Int, source : String } -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
inputCursor { position, source } model =
    if Document.numberOfEditors model.currentDocument > 1 && Predicate.permitExperimentalCollabEditing model.currentUser model.experimentalMode then
        handleCursor { position = position, source = source } model

    else
        ( model, Command.none )


handleCursor : { a | position : Int, source : String } -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleCursor { position, source } model =
    case Maybe.map .id model.currentUser of
        Nothing ->
            ( model, Command.none )

        Just _ ->
            handleEditorChange model position source


inputText : FrontendModel -> Document.SourceTextRecord -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
inputText model { position, source } =
    if
        Document.numberOfEditors model.currentDocument
            > 1
            && Predicate.permitExperimentalCollabEditing model.currentUser model.experimentalMode
    then
        handleEditorChange model position source

    else
        inputText_ model source


inputText_ : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
inputText_ model str =
    let
        -- Push your values here.
        -- This is how we throttle saving the document
        ( debounce, debounceCmd ) =
            Debounce.push debounceConfig str model.debounce
    in
    let
        editRecord =
            Compiler.DifferentialParser.update model.editRecord str

        messages : List String
        messages =
            Render.Markup.getMessages
                editRecord.parsed
    in
    ( { model
        | sourceText = str
        , editRecord = editRecord
        , title = Compiler.ASTTools.title editRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
        , messages = [ { txt = String.join ", " messages, status = MSYellow } ]
        , debounce = debounce
        , counter = model.counter + 1
        , documentDirty = True
      }
    , debounceCmd
    )



--- DEBOUNCE


{-| Here is where documents get saved. This is done
at present every 300 milliseconds. Here is the path:

  - Frontend.Update.save
  - perform the task Saved in Frontend
  - this just makes the call 'Frontend.updateDoc model str'
  - which calls 'Frontend.updateDoc\_ model str'
  - which issues the command 'sendToBackend (SaveDocument newDocument)'
  - which calls 'Backend.Update.saveDocument model document'
  - which updates the documentDict with `Dict.insert document.id { document | modified = model.currentTime } model.documentDict`

This is way too complicated!

-}
debounceMsg : FrontendModel -> Debounce.Msg -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
debounceMsg model msg_ =
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


save : String -> Command FrontendOnly ToBackend FrontendMsg
save s =
    Effect.Task.perform Saved (Effect.Task.succeed s)


debounceConfig : Debounce.Config FrontendMsg
debounceConfig =
    { strategy = Debounce.soon Config.debounceSaveDocumentInterval
    , transform = DebounceMsg
    }



--- RENDER


render : FrontendModel -> MarkupMsg -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
render model msg_ =
    case msg_ of
        Render.Msg.SendMeta _ ->
            -- ( { model | lineNumber = m.loc.begin.row, message = "line " ++ String.fromInt (m.loc.begin.row + 1) }, Cmd.none )
            ( model, Command.none )

        Render.Msg.SendId line ->
            -- TODO: the below (using id also for line number) is not a great idea.
            ( { model | messages = [ { txt = "Line " ++ (line |> String.toInt |> Maybe.withDefault 0 |> (\x -> x + 1) |> String.fromInt), status = MSYellow } ], linenumber = String.toInt line |> Maybe.withDefault 0 }, Command.none )

        Render.Msg.SelectId id ->
            -- the element with this id will be highlighted
            ( { model | selectedId = id }, View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id )

        GetPublicDocument docHandling id ->
            case docHandling of
                MHStandard ->
                    ( { model | messages = { txt = "Fetch (1): " ++ id, status = MSGreen } :: [] }
                    , Effect.Lamdera.sendToBackend (FetchDocumentById Types.StandardHandling id)
                    )

                MHAsCheatSheet ->
                    ( { model | messages = { txt = "Fetch (2): " ++ id, status = MSGreen } :: [] }
                    , Effect.Lamdera.sendToBackend (FetchDocumentById Types.HandleAsManual id)
                    )

        GetPublicDocumentFromAuthor handling authorName searchKey ->
            case handling of
                MHStandard ->
                    ( model, Effect.Lamdera.sendToBackend (FindDocumentByAuthorAndKey Types.StandardHandling authorName searchKey) )

                MHAsCheatSheet ->
                    ( model, Effect.Lamdera.sendToBackend (FindDocumentByAuthorAndKey Types.HandleAsManual authorName searchKey) )

        ProposeSolution proposal ->
            case proposal of
                Solved id ->
                    ( { model | selectedId = id }, Command.none )

                Unsolved ->
                    ( { model | selectedId = "???" }, Command.none )



--- SET PARAM


setLanguage : Bool -> Language -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setLanguage dismiss lang model =
    if dismiss then
        ( { model | language = lang, popupState = NoPopup }, Command.none )
            |> (\( m, _ ) -> changeLanguage m)

    else
        ( { model | language = lang }, Command.none )


changeLanguage : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
changeLanguage model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                newDoc =
                    { doc | language = model.language }
            in
            ( { model | documentDirty = False }
            , Effect.Lamdera.sendToBackend (SaveDocument model.currentUser newDoc)
            )
                |> (\( m, c ) -> ( postProcessDocument newDoc m, c ))


setUserLanguage : Language -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setUserLanguage lang model =
    ( { model | inputLanguage = lang, popupState = NoPopup }, Command.none )



--- SYNC


firstSyncLR : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
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
            , cmd = View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_
            , selectedId = id_
            , searchCount = 0
            }
    in
    ( { model
        | selectedId = data.selectedId
        , foundIds = data.foundIds
        , foundIdIndex = data.foundIdIndex
        , searchCount = data.searchCount
        , messages = [ { txt = ("[" ++ adjustId data.selectedId ++ "]") :: List.map adjustId data.foundIds |> String.join ", ", status = MSWhite } ]
      }
    , data.cmd
    )


nextSyncLR : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
nextSyncLR model =
    let
        id_ =
            List.Extra.getAt model.foundIdIndex model.foundIds |> Maybe.withDefault "(nothing)"
    in
    ( { model
        | selectedId = id_
        , foundIdIndex = modBy (List.length model.foundIds) (model.foundIdIndex + 1)
        , searchCount = model.searchCount + 1
        , messages = [ { txt = ("[" ++ adjustId id_ ++ "]") :: List.map adjustId model.foundIds |> String.join ", ", status = MSWhite } ]
      }
    , View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_
    )


syncLR : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
syncLR model =
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
                , cmd = View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_
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
                , cmd = View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_
                , selectedId = id_
                , searchCount = model.searchCount + 1
                }
    in
    ( { model
        | selectedId = data.selectedId
        , foundIds = data.foundIds
        , foundIdIndex = data.foundIdIndex
        , searchCount = data.searchCount
        , messages = [ { txt = ("!![" ++ adjustId data.selectedId ++ "]") :: List.map adjustId data.foundIds |> String.join ", ", status = MSWhite } ]
      }
    , data.cmd
    )



--- VIEWPORT


setViewportForElement : FrontendModel -> Result xx ( Effect.Browser.Dom.Element, Effect.Browser.Dom.Viewport ) -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setViewportForElement model result =
    case result of
        Ok ( element, viewport ) ->
            ( { model | messages = [] }
              -- [ { txt = model.message ++ ", setting viewport", status = MSNormal } ] }
            , View.Utility.setViewPortForSelectedLine model.popupState element viewport
            )

        Err _ ->
            -- TODO: restore error message
            -- ( { model | message = model.message ++ ", could not set viewport" }, Cmd.none )
            ( model, Command.none )


updateWithViewport : Effect.Browser.Dom.Viewport -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateWithViewport vp model =
    let
        w =
            round vp.viewport.width

        h =
            round vp.viewport.height
    in
    ( { model
        | windowWidth = w
        , windowHeight = h
      }
    , Command.none
    )


addDocToCurrentUser : FrontendModel -> Document -> Maybe User
addDocToCurrentUser model doc =
    case model.currentUser of
        Nothing ->
            Nothing

        Just user ->
            let
                isNotInDeque : Document -> BoundedDeque Document.DocumentInfo -> Bool
                isNotInDeque doc_ deque =
                    BoundedDeque.filter (\item -> item.id == doc_.id) deque |> BoundedDeque.isEmpty

                docs =
                    if isNotInDeque doc user.docs then
                        BoundedDeque.pushFront (Document.toDocInfo doc) user.docs

                    else
                        user.docs
                            |> BoundedDeque.filter (\item -> item.id /= doc.id)
                            |> BoundedDeque.pushFront (Document.toDocInfo doc)

                newUser =
                    { user | docs = docs }
            in
            Just newUser


deleteDocFromCurrentUser : FrontendModel -> Document -> Maybe User
deleteDocFromCurrentUser model doc =
    case model.currentUser of
        Nothing ->
            Nothing

        Just user ->
            let
                newDocs =
                    BoundedDeque.filter (\d -> d.id /= doc.id) user.docs

                newUser =
                    { user | docs = newDocs }
            in
            Just newUser



-- LOCKING AND UNLOCKING DOCUMENTS
--- SPECIAL


runSpecial : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
runSpecial model =
    case model.currentUser of
        Nothing ->
            ( model, Command.none )

        Just user ->
            if user.username == "jxxcarlson" then
                ( model, Effect.Lamdera.sendToBackend (ApplySpecial user model.inputSpecial) )

            else
                ( model, Command.none )



--- URL HANDLING


handleUrlRequest model urlRequest =
    case urlRequest of
        Browser.Internal url ->
            let
                cmd =
                    case .fragment url of
                        Just internalId ->
                            -- internalId is the part after '#', if present
                            View.Utility.setViewportForElement (View.Utility.viewId model.popupState) internalId

                        Nothing ->
                            --if String.left 3 url.path == "/a/" then
                            Effect.Lamdera.sendToBackend (SearchForDocumentsWithAuthorAndKey (String.dropLeft 3 url.path))

                --
                --else if String.left 3 url.path == "/p/" then
                --    sendToBackend (GetDocumentByPublicId (String.dropLeft 3 url.path))
                --
                --else
                --    Nav.pushUrl model.key (Url.toString url)
            in
            ( model, cmd )

        Browser.External url ->
            ( model
            , Effect.Browser.Navigation.load url
            )



--- KEYBOARD COMMANDS


{-| ctrl-S: Left-to-Right sync
-}
updateKeys model keyMsg =
    let
        pressedKeys =
            Keyboard.update keyMsg model.pressedKeys

        doSync =
            if List.member Keyboard.Control pressedKeys && List.member (Keyboard.Character "S") pressedKeys then
                not model.doSync

            else
                model.doSync
    in
    ( { model | pressedKeys = pressedKeys, doSync = doSync, lastInteractionTime = model.currentTime }
    , Command.none
    )



--- UTILITY


adjustId : String -> String
adjustId str =
    case String.toInt str of
        Nothing ->
            str

        Just n ->
            String.fromInt (n + 2)


reject : Bool -> String -> List String -> List String
reject condition message messages =
    if condition then
        message :: messages

    else
        messages
