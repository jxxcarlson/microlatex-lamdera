module Frontend.Update exposing
    ( addDocToCurrentUser
    , adjustId
    , changeLanguage
    , closeEditor
    , debounceMsg
    , exportToLaTeX
    , exportToMarkdown
    , exportToRawLaTeX
    , firstSyncLR
    , handleAsReceivedDocumentWithDelay
    , handleAsStandardReceivedDocument
    , handleCurrentDocumentChange
    , handlePinnedDocuments
    , handleReceivedDocumentAsCheatsheet
    , handleSharedDocument
    , handleSignUp
    , handleUrlRequest
    , hardDeleteDocument
    , inputCursor
    , inputText
    , inputTitle
    , isMaster
    , newDocument
    , nextSyncLR
    , openEditor
    , postProcessDocument
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
    , softDeleteDocument
    , syncLR
    , updateEditRecord
    , updateKeys
    , updateWithViewport
    )

--

import Authentication
import BoundedDeque exposing (BoundedDeque)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Cmd.Extra exposing (withCmd, withNoCmd)
import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OT as OT
import Compiler.ASTTools
import Compiler.Acc
import Compiler.DifferentialParser
import Config
import Debounce
import Dict exposing (Dict)
import Docs
import Document exposing (Document)
import File.Download as Download
import Frontend.Cmd
import IncludeFiles
import Keyboard
import Lamdera exposing (sendToBackend)
import List.Extra
import Markup
import Maybe.Extra
import Message
import Parser.Language exposing (Language(..))
import Predicate
import Process
import Render.LaTeX as LaTeX
import Render.Markup
import Render.Msg exposing (Handling(..), MarkupMsg(..), SolutionState(..))
import Render.Settings as Settings
import Share
import String.Extra
import Task
import Time
import Types exposing (DocumentDeleteState(..), DocumentHandling(..), DocumentList(..), FrontendModel, FrontendMsg(..), MessageStatus(..), PhoneMode(..), PopupState(..), ToBackend(..))
import User exposing (User)
import Util
import View.Utility


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
                    , documents = Util.updateDocumentInList updatedDoc model.documents
                }
        in
        setDocumentAsCurrent (sendToBackend (SaveDocument model.currentUser updatedDoc)) newModel document StandardHandling

    else if currentDocument.status == Document.DSCanEdit then
        let
            updatedDoc =
                { currentDocument | status = Document.DSReadOnly }

            newModel =
                { model | selectedSlug = Document.getSlug currentDocument, documents = Util.updateDocumentInList updatedDoc model.documents, language = document.language }
        in
        setDocumentAsCurrent (sendToBackend (SaveDocument model.currentUser updatedDoc)) newModel document StandardHandling

    else
        setDocumentAsCurrent Cmd.none model document StandardHandling


setDocumentAsCurrent : Cmd FrontendMsg -> FrontendModel -> Document.Document -> DocumentHandling -> ( FrontendModel, Cmd FrontendMsg )
setDocumentAsCurrent cmd model doc permissions =
    -- TODO!
    let
        filesToInclude =
            IncludeFiles.getData doc.content
    in
    case List.isEmpty filesToInclude of
        True ->
            setDocumentAsCurrent_ cmd model doc permissions

        False ->
            setDocumentAsCurrent_ (Cmd.batch [ cmd, sendToBackend (GetIncludedFiles doc filesToInclude) ]) model doc permissions


getIncludedFiles : Document -> Cmd FrontendMsg
getIncludedFiles doc =
    -- TODO!
    let
        filesToInclude =
            IncludeFiles.getData doc.content
    in
    case List.isEmpty filesToInclude of
        True ->
            Cmd.none

        False ->
            sendToBackend (GetIncludedFiles doc filesToInclude)


{-| }
When the editor is opened, the current user is added to the document's
current editor list. This changed needs to saved to the backend and
narrowcast to the other users who to whom this document is shared,
so that **all** relevant frontends remain in sync. Otherwise there
will be shared set of editors among the various users editing the document.
-}
openEditor : Document -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
openEditor doc model =
    case model.currentUser of
        Nothing ->
            ( model, Cmd.none )

        Just user ->
            let
                oldEditorList =
                    doc.currentEditorList

                equal a b =
                    a.userId == b.userId

                editorItem : Document.EditorData
                editorItem =
                    { userId = user.id, username = user.username }

                currentEditorList =
                    Util.insertInListOrUpdate equal editorItem oldEditorList

                updatedDoc =
                    { doc | status = Document.DSCanEdit, currentEditorList = currentEditorList }

                sendersName =
                    Util.currentUsername model.currentUser

                sendersId =
                    Util.currentUserId model.currentUser
            in
            ( { model
                | showEditor = True
                , sourceText = doc.content
                , initialText = ""
                , currentDocument = Just updatedDoc
              }
            , Cmd.batch
                [ Frontend.Cmd.setInitialEditorContent 20
                , if Predicate.documentIsMineOrIAmAnEditor (Just doc) model.currentUser then
                    sendToBackend (AddEditor user updatedDoc)

                  else
                    Cmd.none
                , sendToBackend (NarrowcastExceptToSender sendersName sendersId updatedDoc)
                ]
            )


closeEditor : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
closeEditor model =
    let
        --mCurrentEditor : Maybe String
        --mCurrentEditor =
        --    model.currentDocument |> Maybe.andThen .currentEditor
        mCurrentUsername : Maybe String
        mCurrentUsername =
            model.currentUser |> Maybe.map .username

        currentEditors =
            model.currentDocument
                |> Maybe.map .currentEditorList
                |> Maybe.withDefault []
                |> List.filter (\item -> Just item.username /= mCurrentUsername)

        updatedDoc =
            User.mRemoveEditor model.currentUser model.currentDocument

        saveCmd =
            case updatedDoc of
                Nothing ->
                    Cmd.none

                Just doc ->
                    Cmd.batch
                        [ sendToBackend (SaveDocument model.currentUser doc)
                        , sendToBackend (NarrowcastExceptToSender (Util.currentUsername model.currentUser) (Util.currentUserId model.currentUser) doc)
                        ]

        clearEditEventsCmd =
            sendToBackend (ClearEditEvents (Util.currentUserId model.currentUser))
    in
    ( { model | currentDocument = updatedDoc, initialText = "", popupState = NoPopup, showEditor = False }, saveCmd )


apply :
    (FrontendModel -> ( FrontendModel, Cmd FrontendMsg ))
    -> FrontendModel
    -> ( FrontendModel, Cmd FrontendMsg )
apply f model =
    f model


andThenApply :
    (FrontendModel -> ( FrontendModel, Cmd FrontendMsg ))
    -> ( FrontendModel, Cmd FrontendMsg )
    -> ( FrontendModel, Cmd FrontendMsg )
andThenApply f ( model, cmd ) =
    let
        ( model2, cmd2 ) =
            f model
    in
    ( model2, Cmd.batch [ cmd, cmd2 ] )


joinF : ( FrontendModel, Cmd FrontendMsg ) -> (FrontendModel -> ( FrontendModel, Cmd FrontendMsg )) -> ( FrontendModel, Cmd FrontendMsg )
joinF ( model1, cmd1 ) f =
    let
        ( model2, cmd2 ) =
            f model1
    in
    ( model2, Cmd.batch [ cmd1, cmd2 ] )


updateEditRecord : Dict String String -> Document -> FrontendModel -> FrontendModel
updateEditRecord inclusionData doc model =
    { model | editRecord = Compiler.DifferentialParser.init inclusionData doc.language doc.content }


setDocumentAsCurrent_ : Cmd FrontendMsg -> FrontendModel -> Document.Document -> DocumentHandling -> ( FrontendModel, Cmd FrontendMsg )
setDocumentAsCurrent_ cmd model doc permissions =
    let
        newOTDocument =
            { id = doc.id, cursor = 0, x = 0, y = 0, content = doc.content }

        -- For now, loc the doc in all cases
        currentUserName_ : String
        currentUserName_ =
            Util.currentUsername model.currentUser

        newEditRecord : Compiler.DifferentialParser.EditRecord
        newEditRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        -- filesToInclude =
        --    newEditRecord.includedFiles
        errorMessages : List Types.Message
        errorMessages =
            Message.make (newEditRecord.messages |> String.join "; ") MSYellow

        currentMasterDocument =
            if isMaster newEditRecord then
                Just doc

            else
                Nothing

        ( readers, editors ) =
            View.Utility.getReadersAndEditors (Just doc)

        newCurrentUser =
            addDocToCurrentUser model doc

        newDocumentStatus =
            if Predicate.documentIsMineOrSharedToMe (Just doc) model.currentUser && model.showEditor then
                Document.DSCanEdit

            else
                Document.DSReadOnly

        updatedDoc =
            { doc | status = newDocumentStatus }
    in
    ( { model
        | currentDocument = Just updatedDoc
        , selectedSlug = Document.getSlug updatedDoc
        , currentMasterDocument = currentMasterDocument
        , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (Util.currentUserId model.currentUser) doc.content)
        , sourceText = doc.content
        , initialText = doc.content
        , documents = Util.updateDocumentInList updatedDoc model.documents
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
    , Cmd.batch
        [ View.Utility.setViewPortToTop model.popupState
        , Cmd.batch [ cmd, sendToBackend (SaveDocument model.currentUser updatedDoc) ]
        , Nav.pushUrl model.key ("/c/" ++ doc.id)
        ]
    )


handleReceivedDocumentAsCheatsheet model doc =
    ( { model
        | currentCheatsheet = Just doc
        , counter = model.counter + 1
        , messages =
            { txt = "Cheatsheet: " ++ doc.title, status = MSGreen } :: []
      }
    , Cmd.none
    )


handleAsStandardReceivedDocument model doc =
    let
        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        errorMessages : List Types.Message
        errorMessages =
            Message.make (editRecord.messages |> String.join "; ") MSYellow

        currentMasterDocument =
            if isMaster editRecord then
                Just doc

            else
                model.currentMasterDocument
    in
    ( { model
        | editRecord = editRecord
        , selectedSlug = Document.getSlug doc
        , title = Compiler.ASTTools.title editRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
        , documents = Util.updateDocumentInList doc model.documents -- insertInListOrUpdate
        , currentDocument = Just doc
        , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (Util.currentUserId model.currentUser) doc.content)
        , sourceText = doc.content
        , messages = { txt = "Received (std): " ++ doc.title, status = MSGreen } :: []
        , currentMasterDocument = currentMasterDocument
        , counter = model.counter + 1
      }
    , Cmd.batch
        [ savePreviousCurrentDocumentCmd model
        , Frontend.Cmd.setInitialEditorContent 20
        , View.Utility.setViewPortToTop model.popupState
        ]
    )


handleSharedDocument model username doc =
    let
        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        errorMessages : List Types.Message
        errorMessages =
            Message.make (editRecord.messages |> String.join "; ") MSYellow

        currentMasterDocument =
            if isMaster editRecord then
                Just doc

            else
                model.currentMasterDocument
    in
    ( { model
        | editRecord = editRecord
        , title = Compiler.ASTTools.title editRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
        , documents = Util.updateDocumentInList doc model.documents -- insertInListOrUpdate
        , currentDocument = Just doc
        , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (Util.currentUserId model.currentUser) doc.content)
        , sourceText = doc.content
        , activeEditor = Just { name = username, activeAt = model.currentTime }
        , messages = { txt = "Received (shared): " ++ doc.title, status = MSGreen } :: []
        , currentMasterDocument = currentMasterDocument
        , counter = model.counter + 1
      }
    , Cmd.batch [ savePreviousCurrentDocumentCmd model, Frontend.Cmd.setInitialEditorContent 20, View.Utility.setViewPortToTop model.popupState ]
    )


{-| Use this function to ensure that edits to the current document are saved
before the current documen is changed
-}
savePreviousCurrentDocumentCmd : FrontendModel -> Cmd FrontendMsg
savePreviousCurrentDocumentCmd model =
    case model.currentDocument of
        Nothing ->
            Cmd.none

        Just previousDoc ->
            if model.documentDirty && previousDoc.status == Document.DSCanEdit then
                let
                    previousDoc2 =
                        -- TODO: change content
                        { previousDoc | content = model.sourceText }
                in
                sendToBackend (SaveDocument model.currentUser previousDoc2)

            else
                Cmd.none


handleAsReceivedDocumentWithDelay model doc =
    let
        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        errorMessages : List Types.Message
        errorMessages =
            Message.make (editRecord.messages |> String.join "; ") MSYellow

        currentMasterDocument =
            if isMaster editRecord then
                Just doc

            else
                model.currentMasterDocument
    in
    ( { model
        | editRecord = editRecord
        , title = Compiler.ASTTools.title editRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
        , documents = Util.updateDocumentInList doc model.documents -- insertInListOrUpdate
        , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (Util.currentUserId model.currentUser) doc.content)
        , currentDocument = Just doc
        , sourceText = doc.content
        , messages = errorMessages
        , currentMasterDocument = currentMasterDocument
        , counter = model.counter + 1
      }
    , Cmd.batch [ Util.delay 200 (SetDocumentCurrent doc), Frontend.Cmd.setInitialEditorContent 20, View.Utility.setViewPortToTop model.popupState ]
    )


handlePinnedDocuments model doc =
    let
        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        errorMessages : List Types.Message
        errorMessages =
            Message.make (editRecord.messages |> String.join "; ") MSYellow

        currentMasterDocument =
            if isMaster editRecord then
                Just doc

            else
                model.currentMasterDocument
    in
    ( { model
        | editRecord = editRecord
        , title = Compiler.ASTTools.title editRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
        , pinned = Util.updateDocumentInList doc model.documents -- insertInListOrUpdate
        , currentDocument = Just doc
        , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (Util.currentUserId model.currentUser) doc.content)
        , sourceText = doc.content
        , messages = errorMessages
        , currentMasterDocument = currentMasterDocument
        , counter = model.counter + 1
      }
    , Cmd.batch [ Frontend.Cmd.setInitialEditorContent 20, View.Utility.setViewPortToTop model.popupState ]
    )


exportToLaTeX model =
    let
        textToExport =
            LaTeX.export Settings.defaultSettings model.editRecord.parsed

        fileName =
            (model.currentDocument |> Maybe.map .title |> Maybe.withDefault "doc") ++ ".tex"
    in
    ( model, Download.string fileName "application/x-latex" textToExport )


exportToRawLaTeX model =
    let
        textToExport =
            LaTeX.rawExport Settings.defaultSettings model.editRecord.parsed

        fileName =
            (model.currentDocument |> Maybe.map .title |> Maybe.withDefault "doc") ++ ".tex"
    in
    ( model, Download.string fileName "application/x-latex" textToExport )


exportToMarkdown model =
    let
        markdownText =
            -- TODO:implement this
            -- L1.Render.Markdown.transformDocument model.currentDocument.content
            "Not implemented"

        fileName_ =
            "foo" |> String.replace " " "-" |> String.toLower |> (\name -> name ++ ".md")
    in
    ( model, Download.string fileName_ "text/markdown" markdownText )


setPublic model doc public =
    let
        newDocument_ =
            { doc | public = public }

        documents =
            List.Extra.setIf (\d -> d.id == newDocument_.id) newDocument_ model.documents
    in
    ( { model | documents = documents, documentDirty = False, currentDocument = Just newDocument_, inputTitle = "" }, sendToBackend (SaveDocument model.currentUser newDocument_) )


setPublicDocumentAsCurrentById : FrontendModel -> String -> ( FrontendModel, Cmd FrontendMsg )
setPublicDocumentAsCurrentById model id =
    case List.filter (\doc -> doc.id == id) model.publicDocuments |> List.head of
        Nothing ->
            ( { model | messages = [ { txt = "No document of id [" ++ id ++ "] found", status = MSWhite } ] }, Cmd.none )

        Just doc ->
            let
                newEditRecord =
                    Compiler.DifferentialParser.init model.includedContent doc.language doc.content
            in
            ( { model
                | currentDocument = Just doc
                , networkModel = NetworkModel.init (NetworkModel.initialServerState doc.id (Util.currentUserId model.currentUser) doc.content)
                , sourceText = doc.content
                , initialText = doc.content
                , editRecord = newEditRecord
                , title = Compiler.ASTTools.title newEditRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
                , messages = [ { txt = "id = " ++ doc.id, status = MSWhite } ]
                , counter = model.counter + 1
              }
            , Cmd.batch [ View.Utility.setViewPortToTop model.popupState ]
            )


softDeleteDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Cmd.none )

        Just doc ->
            let
                newUser =
                    case model.currentUser of
                        Nothing ->
                            Nothing

                        Just _ ->
                            deleteDocFromCurrentUser model doc

                ( newDoc, currentDocument, newDocuments ) =
                    if doc.status == Document.DSSoftDelete then
                        ( { doc | status = Document.DSCanEdit }, model.currentDocument, model.documents )

                    else
                        ( { doc | status = Document.DSSoftDelete }, Just Docs.deleted, List.filter (\d -> d.id /= doc.id) model.documents )
            in
            ( { model
                | currentDocument = currentDocument
                , documents = newDocuments
                , documentDirty = False
                , deleteDocumentState = WaitingForDeleteAction
                , currentUser = newUser
              }
            , Cmd.batch [ sendToBackend (SaveDocument model.currentUser newDoc), Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById Config.documentDeletedNotice)) ]
            )


hardDeleteDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Cmd.none )

        Just doc ->
            let
                newUser =
                    case model.currentUser of
                        Nothing ->
                            Nothing

                        Just _ ->
                            deleteDocFromCurrentUser model doc
            in
            ( { model
                | currentDocument = Just Docs.deleted
                , documents = List.filter (\d -> d.id /= doc.id) model.documents
                , hardDeleteDocumentState = Types.WaitingForHardDeleteAction
                , currentUser = newUser
              }
            , Cmd.batch [ sendToBackend (HardDeleteDocumentBE doc), Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById Config.documentDeletedNotice)) ]
            )


setInitialEditorContent model =
    case model.currentDocument of
        Nothing ->
            ( { model | messages = [ { txt = "Could not set editor content: there is no current document", status = MSWhite } ] }, Cmd.none )

        Just doc ->
            ( { model | initialText = doc.content }, Cmd.none )


searchText model =
    let
        ids =
            Compiler.ASTTools.matchingIdsInAST model.searchSourceText model.editRecord.parsed

        ( cmd, id ) =
            case List.head ids of
                Nothing ->
                    ( Cmd.none, "(none)" )

                Just id_ ->
                    ( View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id_, id_ )
    in
    ( { model | selectedId = id, searchCount = model.searchCount + 1, messages = [ { txt = "ids: " ++ String.join ", " ids, status = MSWhite } ] }, cmd )


inputTitle model str =
    ( { model | inputTitle = str }, Cmd.none )



-- INPUT FROM THE CODEMIRROR EDITOR (CHANGES IN CURSOR, TEXT)


inputCursor : { position : Int, source : String } -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
inputCursor { position, source } model =
    if Document.numberOfEditors model.currentDocument > 1 then
        handleCursor { position = position, source = source } model

    else
        ( model, Cmd.none )


handleCursor : { a | position : Int, source : String } -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
handleCursor { position, source } model =
    case Maybe.map .id model.currentUser of
        Nothing ->
            ( model, Cmd.none )

        Just currentUserId ->
            --let
            --    id =
            --        model.networkModel.serverState.document.id
            --
            --    newOTDocument =
            --        { id = id, cursor = position, content = source } |> Debug.log "!!! NEW OT DOC"
            --
            --    editEvent =
            --        NetworkModel.createEvent currentUserId model.networkModel.serverState.document newOTDocument |> Debug.log "!! NEW EDIT EVENT"
            --in
            --( { model | editorCursor = position |> Debug.log "!!! CURSOR" }, sendToBackend (PushEditorEvent editEvent) )
            handleEditorChange model position source


inputText : FrontendModel -> Document.SourceTextRecord -> ( FrontendModel, Cmd FrontendMsg )
inputText model { position, source } =
    if Document.numberOfEditors model.currentDocument > 123 then
        handleEditorChange model position source

    else
        inputText_ model source


{-|

    From the cursor, content information received from the editor (on cursor or text change),
    compute the editEvent, where it will be sent to the backend, then narrowcast to
    the clients current editing the given shared document.

-}
handleEditorChange : FrontendModel -> Int -> String -> ( FrontendModel, Cmd FrontendMsg )
handleEditorChange model cursor content =
    let
        newOTDocument =
            let
                id =
                    Maybe.map .id model.currentDocument |> Maybe.withDefault "---"
            in
            { docId = id, cursor = cursor, content = content }

        userId =
            model.currentUser |> Maybe.map .id |> Maybe.withDefault "---"

        oldDocument =
            model.networkModel.serverState.document

        editEvent =
            NetworkModel.createEvent userId oldDocument newOTDocument
    in
    ( { model | counter = model.counter + 1 }, sendToBackend (PushEditorEvent editEvent) )


inputText_ : FrontendModel -> String -> ( FrontendModel, Cmd FrontendMsg )
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


save : String -> Cmd FrontendMsg
save s =
    Task.perform Saved (Task.succeed s)


debounceConfig : Debounce.Config FrontendMsg
debounceConfig =
    { strategy = Debounce.soon Config.debounceSaveDocumentInterval
    , transform = DebounceMsg
    }


render model msg_ =
    case msg_ of
        Render.Msg.SendMeta _ ->
            -- ( { model | lineNumber = m.loc.begin.row, message = "line " ++ String.fromInt (m.loc.begin.row + 1) }, Cmd.none )
            ( model, Cmd.none )

        Render.Msg.SendId line ->
            -- TODO: the below (using id also for line number) is not a great idea.
            ( { model | messages = [ { txt = "Line " ++ (line |> String.toInt |> Maybe.withDefault 0 |> (\x -> x + 1) |> String.fromInt), status = MSYellow } ], linenumber = String.toInt line |> Maybe.withDefault 0 }, Cmd.none )

        Render.Msg.SelectId id ->
            -- the element with this id will be highlighted
            ( { model | selectedId = id }, View.Utility.setViewportForElement (View.Utility.viewId model.popupState) id )

        GetPublicDocument docHandling id ->
            case docHandling of
                MHStandard ->
                    ( { model | messages = { txt = "Fetch (1): " ++ id, status = MSGreen } :: [] }
                    , sendToBackend (FetchDocumentById Types.StandardHandling id)
                    )

                MHAsCheatSheet ->
                    ( { model | messages = { txt = "Fetch (2): " ++ id, status = MSGreen } :: [] }
                    , sendToBackend (FetchDocumentById Types.HandleAsCheatSheet id)
                    )

        GetPublicDocumentFromAuthor handling authorName searchKey ->
            case handling of
                MHStandard ->
                    ( model, sendToBackend (FindDocumentByAuthorAndKey Types.StandardHandling authorName searchKey) )

                MHAsCheatSheet ->
                    ( model, sendToBackend (FindDocumentByAuthorAndKey Types.HandleAsCheatSheet authorName searchKey) )

        ProposeSolution proposal ->
            case proposal of
                Solved id ->
                    ( { model | selectedId = id }, Cmd.none )

                Unsolved ->
                    ( { model | selectedId = "???" }, Cmd.none )


setLanguage dismiss lang model =
    if dismiss then
        ( { model | language = lang, popupState = NoPopup }, Cmd.none )
            |> (\( m, _ ) -> changeLanguage m)

    else
        ( { model | language = lang }, Cmd.none )


setUserLanguage lang model =
    ( { model | inputLanguage = lang, popupState = NoPopup }, Cmd.none )


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


adjustId : String -> String
adjustId str =
    case String.toInt str of
        Nothing ->
            str

        Just n ->
            String.fromInt (n + 2)


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
            ( model, Cmd.none )


isMaster editRecord =
    Compiler.ASTTools.existsBlockWithName editRecord.parsed "collection"


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


requestRefresh : String -> ( FrontendModel, List (Cmd FrontendMsg) ) -> ( FrontendModel, List (Cmd FrontendMsg) )
requestRefresh docId ( model, cmds ) =
    let
        message =
            { txt = "Requesting refresh for " ++ docId, status = MSGreen }
    in
    ( { model | messages = message :: model.messages }, sendToBackend (RequestRefresh docId) :: cmds )


currentUserName : Maybe User -> String
currentUserName mUser =
    mUser |> Maybe.map .username |> Maybe.withDefault "((nobody))"


currentDocumentId : Maybe Document -> String
currentDocumentId mDoc =
    mDoc |> Maybe.map .id |> Maybe.withDefault "((no docId))"


shouldMakeRequest : Maybe User -> Document -> Bool -> Bool
shouldMakeRequest mUser doc showEditor =
    -- Predicate.isSharedToMe mUser doc
    Predicate.isSharedToMe (Just doc) mUser
        || Predicate.documentIsMineOrSharedToMe (Just doc) mUser


changeLanguage model =
    case model.currentDocument of
        Nothing ->
            ( model, Cmd.none )

        Just doc ->
            let
                newDoc =
                    { doc | language = model.language }
            in
            ( { model | documentDirty = False }
            , sendToBackend (SaveDocument model.currentUser newDoc)
            )
                |> (\( m, c ) -> ( postProcessDocument newDoc m, c ))


saveDocument : Maybe Document -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
saveDocument mDoc model =
    case mDoc of
        Nothing ->
            ( model, Cmd.none )

        Just doc ->
            ( { model | documentDirty = False }, sendToBackend (SaveDocument model.currentUser doc) )


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



-- OPEN AND CLOSE EDITOR


join :
    (FrontendModel -> ( FrontendModel, Cmd FrontendMsg ))
    -> (FrontendModel -> ( FrontendModel, Cmd FrontendMsg ))
    -> (FrontendModel -> ( FrontendModel, Cmd FrontendMsg ))
join f g =
    \m ->
        let
            ( m1, cmd1 ) =
                f m

            ( m2, cmd2 ) =
                g m1
        in
        ( m2, Cmd.batch [ cmd1, cmd2 ] )



-- END: LOCKING AND UNLOCKING DOCUMENTS


setPermissions currentUser permissions document =
    case document.author of
        Nothing ->
            permissions

        Just author ->
            if Just author == Maybe.map .username currentUser then
                StandardHandling

            else
                permissions


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


runSpecial model =
    case model.currentUser of
        Nothing ->
            model |> withNoCmd

        Just user ->
            if user.username == "jxxcarlson" then
                model |> withCmd (sendToBackend (ApplySpecial user model.inputSpecial))

            else
                model |> withNoCmd


signOut model =
    let
        cmd =
            case model.currentUser of
                Nothing ->
                    Cmd.none

                Just user ->
                    sendToBackend (UpdateUserWith user)
    in
    ( { model
        | currentUser = Nothing
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
        , lastInteractionTime = Time.millisToPosix 0
      }
    , Cmd.batch
        [ Nav.pushUrl model.key "/"
        , cmd
        , sendToBackend (SignOutBE (model.currentUser |> Maybe.map .username))
        , sendToBackend (GetDocumentById Types.StandardHandling Config.welcomeDocId)
        , sendToBackend (GetPublicDocuments Types.SortByMostRecent Nothing)
        ]
    )



-- |> join (unshare (Util.currentUsername model.currentUser))
-- narrowCast : Username -> Document.Document -> Types.ConnectionDict -> Cmd Types.BackendMsg
--     , Cmd.batch (narrowCastDocs model username documents)


signIn model =
    if String.length model.inputPassword >= 8 then
        case Config.defaultUrl of
            Nothing ->
                ( model, sendToBackend (SignInBE model.inputUsername (Authentication.encryptForTransit model.inputPassword)) )

            Just url ->
                ( { model | url = url }, sendToBackend (SignInBE model.inputUsername (Authentication.encryptForTransit model.inputPassword)) )

    else
        ( { model | messages = [ { txt = "Password must be at least 8 letters long.", status = MSWhite } ] }, Cmd.none )


handleSignUp model =
    let
        errors =
            []
                |> reject (String.length model.inputUsername < 3) "username: at least three letters"
                |> reject (String.toLower model.inputUsername /= model.inputUsername) "username: all lower case characters"
                |> reject (model.inputPassword == "") "password: cannot be empty"
                |> reject (String.length model.inputPassword < 8) "password: at least 8 letters long."
                |> reject (model.inputPassword /= model.inputPasswordAgain) "passwords do not match"
                |> reject (model.inputEmail == "") "missing email address"
                |> reject (model.inputRealname == "") "missing real name"
    in
    if List.isEmpty errors then
        ( model
        , sendToBackend (SignUpBE model.inputUsername model.inputLanguage (Authentication.encryptForTransit model.inputPassword) model.inputRealname model.inputEmail)
        )

    else
        ( { model | messages = [ { txt = String.join "; " errors, status = MSWhite } ] }, Cmd.none )


reject : Bool -> String -> List String -> List String
reject condition message messages =
    if condition then
        message :: messages

    else
        messages


handleUrlRequest model urlRequest =
    case urlRequest of
        Internal url ->
            let
                cmd =
                    case .fragment url of
                        Just internalId ->
                            -- internalId is the part after '#', if present
                            View.Utility.setViewportForElement (View.Utility.viewId model.popupState) internalId

                        Nothing ->
                            --if String.left 3 url.path == "/a/" then
                            sendToBackend (SearchForDocumentsWithAuthorAndKey (String.dropLeft 3 url.path))

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
    , Cmd.none
    )


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
    , Cmd.none
    )


newDocument model =
    let
        emptyDoc =
            Document.empty

        documentsCreatedCounter =
            model.documentsCreatedCounter + 1

        title =
            case model.language of
                MicroLaTeXLang ->
                    "\\title{" ++ model.inputTitle ++ "}\n\n"

                _ ->
                    "| title\n" ++ model.inputTitle ++ "\n\n"

        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        doc =
            { emptyDoc
                | title = title
                , content = title
                , author = Maybe.map .username model.currentUser
                , language = model.language
            }
    in
    ( { model
        | showEditor = True
        , inputTitle = ""
        , title = Compiler.ASTTools.title editRecord.parsed

        --, editRecord = editRecord
        -- , documents = doc::model.documents
        , documentsCreatedCounter = documentsCreatedCounter
        , popupState = NoPopup
      }
    , Cmd.batch [ sendToBackend (CreateDocument model.currentUser doc) ]
    )



-- SAVE DOCUMENT TOOLS


saveDocumentToBackend : Maybe User -> Document.Document -> Cmd FrontendMsg
saveDocumentToBackend currentUser doc =
    case doc.status of
        Document.DSSoftDelete ->
            Cmd.none

        Document.DSReadOnly ->
            Cmd.none

        Document.DSCanEdit ->
            sendToBackend (SaveDocument currentUser doc)


saveCurrentDocumentToBackend : Maybe Document.Document -> Maybe User -> Cmd FrontendMsg
saveCurrentDocumentToBackend mDoc mUser =
    case mDoc of
        Nothing ->
            Cmd.none

        Just doc ->
            case doc.status of
                Document.DSSoftDelete ->
                    Cmd.none

                Document.DSReadOnly ->
                    Cmd.none

                Document.DSCanEdit ->
                    sendToBackend (SaveDocument mUser doc)



-- SORT
