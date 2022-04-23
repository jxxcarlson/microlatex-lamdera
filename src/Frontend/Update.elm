module Frontend.Update exposing
    ( addDocToCurrentUser
    , adjustId
    , changeLanguage
    , closeEditor
    , currentDocumentPostProcess
    , debounceMsg
    , exportToLaTeX
    , exportToMarkdown
    , firstSyncLR
    , handleAsReceivedDocumentWithDelay
    , handleAsStandardReceivedDocument
    , handleCurrentDocumentChange
    , handlePinnedDocuments
    , handleReceivedDocumentAsCheatsheet
    , handleSignIn
    , handleSignUp
    , handleUrlRequest
    , hardDeleteDocument
    , inputText
    , inputTitle
    , isMaster
    , lockCurrentDocumentUnconditionally
    , lockDocument
    , newDocument
    , nextSyncLR
    , openEditor
    , preserveCurrentDocument
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
    , signOut
    , softDeleteDocument
    , syncLR
    , unlockCurrentDocument
    , updateCurrentDocument
    , updateKeys
    , updateWithViewport
    )

--

import Authentication
import BoundedDeque exposing (BoundedDeque)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Cmd.Extra exposing (withCmd, withNoCmd)
import Compiler.ASTTools
import Compiler.Acc
import Compiler.DifferentialParser
import Config
import Debounce
import Dict
import Docs
import Document exposing (Document)
import File.Download as Download
import Frontend.Cmd
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
import Render.Msg exposing (MarkupMsg(..), SolutionState(..))
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
    if model.documentDirty && currentDocument.status == Document.DSNormal then
        -- we are leaving the old current document.
        -- make sure that the content is saved and its status is set to read only
        let
            updatedDoc =
                { currentDocument | content = model.sourceText, status = Document.DSReadOnly }

            newModel =
                { model | documentDirty = False, documents = Util.updateDocumentInList updatedDoc model.documents }
        in
        setDocumentAsCurrent (sendToBackend (SaveDocument updatedDoc)) newModel document StandardHandling

    else if currentDocument.status == Document.DSNormal then
        let
            updatedDoc =
                { currentDocument | status = Document.DSReadOnly }

            newModel =
                { model | documents = Util.updateDocumentInList updatedDoc model.documents }
        in
        setDocumentAsCurrent (sendToBackend (SaveDocument updatedDoc)) newModel document StandardHandling

    else
        setDocumentAsCurrent Cmd.none model document StandardHandling


setDocumentAsCurrent : Cmd FrontendMsg -> FrontendModel -> Document.Document -> DocumentHandling -> ( FrontendModel, Cmd FrontendMsg )
setDocumentAsCurrent cmd model doc permissions =
    let
        -- For now, loc the doc in all cases
        currentUserName_ : String
        currentUserName_ =
            Util.currentUsername model.currentUser

        newEditRecord : Compiler.DifferentialParser.EditRecord
        newEditRecord =
            Compiler.DifferentialParser.init doc.language doc.content

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
                Document.DSNormal

            else
                Document.DSReadOnly

        updatedDoc =
            { doc | status = newDocumentStatus }
    in
    ( { model
        | currentDocument = Just updatedDoc
        , currentMasterDocument = currentMasterDocument
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
        , Cmd.batch [ cmd, sendToBackend (SaveDocument updatedDoc) ]
        , Nav.pushUrl model.key ("/c/" ++ doc.id)
        ]
    )


handleReceivedDocumentAsCheatsheet model doc =
    ( { model
        | currentCheatsheet = Just doc
        , counter = model.counter + 1
      }
    , Cmd.none
    )


handleAsStandardReceivedDocument model doc =
    let
        editRecord =
            Compiler.DifferentialParser.init doc.language doc.content

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
        , sourceText = doc.content
        , messages = errorMessages
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
            if model.documentDirty && previousDoc.status == Document.DSNormal then
                let
                    previousDoc2 =
                        -- TODO: change content
                        { previousDoc | content = model.sourceText }
                in
                sendToBackend (SaveDocument previousDoc2)

            else
                Cmd.none


handleAsReceivedDocumentWithDelay model doc =
    let
        editRecord =
            Compiler.DifferentialParser.init doc.language doc.content

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
            Compiler.DifferentialParser.init doc.language doc.content

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
    ( { model | documents = documents, documentDirty = False, currentDocument = Just newDocument_, inputTitle = "" }, sendToBackend (SaveDocument newDocument_) )


setPublicDocumentAsCurrentById : FrontendModel -> String -> ( FrontendModel, Cmd FrontendMsg )
setPublicDocumentAsCurrentById model id =
    case List.filter (\doc -> doc.id == id) model.publicDocuments |> List.head of
        Nothing ->
            ( { model | messages = [ { txt = "No document of id [" ++ id ++ "] found", status = MSWhite } ] }, Cmd.none )

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
                        ( { doc | status = Document.DSNormal }, model.currentDocument, model.documents )

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
            , Cmd.batch [ sendToBackend (SaveDocument newDoc), Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById Config.documentDeletedNotice)) ]
            )



-- |> (\( m, c ) -> ( currentDocumentPostProcess newDoc m, c ))


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


inputText : FrontendModel -> String -> ( FrontendModel, Cmd FrontendMsg )
inputText model str =
    if Share.canEdit model.currentUser model.currentDocument then
        inputText_ model str

    else if Maybe.map .share model.currentDocument == Just Document.NotShared then
        ( model, Cmd.none )

    else
        ( { model | messages = Message.make "Doc shared; lock to edit it." MSRed }, Cmd.none )


inputText_ : FrontendModel -> String -> ( FrontendModel, Cmd FrontendMsg )
inputText_ model str =
    let
        -- Push your values here.
        -- This is how we throttle saving the document
        ( debounce, cmd ) =
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
    , cmd
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

        GetPublicDocument id ->
            ( model, sendToBackend (FetchDocumentById Types.StandardHandling id) )

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
            , sendToBackend (SaveDocument newDoc)
            )
                |> (\( m, c ) -> ( currentDocumentPostProcess newDoc m, c ))


saveDocument : Maybe Document -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
saveDocument mDoc model =
    case mDoc of
        Nothing ->
            ( model, Cmd.none )

        Just doc ->
            ( { model | documentDirty = False }, sendToBackend (SaveDocument doc) )


joinF : ( FrontendModel, Cmd FrontendMsg ) -> (FrontendModel -> ( FrontendModel, Cmd FrontendMsg )) -> ( FrontendModel, Cmd FrontendMsg )
joinF ( model1, cmd1 ) f =
    let
        ( model2, cmd2 ) =
            f model1
    in
    ( model2, Cmd.batch [ cmd1, cmd2 ] )


currentDocumentPostProcess : Document.Document -> FrontendModel -> FrontendModel
currentDocumentPostProcess doc model =
    let
        newEditRecord : Compiler.DifferentialParser.EditRecord
        newEditRecord =
            Compiler.DifferentialParser.init doc.language doc.content

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


lockCurrentDocumentUnconditionally : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
lockCurrentDocumentUnconditionally model =
    case model.currentDocument of
        Nothing ->
            ( model, Cmd.none )

        Just doc_ ->
            let
                currentUsername =
                    Util.currentUsername model.currentUser

                doc =
                    { doc_ | currentEditor = Just currentUsername }
            in
            ( { model
                | currentDocument = Just doc
                , documentDirty = False
                , documents = Util.updateDocumentInList doc model.documents
              }
            , Cmd.batch
                [ sendToBackend (SaveDocument doc)
                , sendToBackend (Narrowcast currentUsername doc)
                ]
            )


lockCurrentDocument : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
lockCurrentDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Cmd.none )

        Just doc_ ->
            if doc_.currentEditor == Nothing then
                let
                    currentUsername =
                        Util.currentUsername model.currentUser

                    doc =
                        { doc_ | currentEditor = Just currentUsername }
                in
                ( { model
                    | currentDocument = Just doc
                    , documents = Util.updateDocumentInList doc model.documents
                    , messages = Message.make "Document locked" MSGreen
                    , documentDirty = False
                  }
                , Cmd.batch
                    [ sendToBackend (SaveDocument doc)
                    , sendToBackend (Narrowcast currentUsername doc)
                    ]
                )

            else
                ( { model | messages = Message.make "Document is locked already" MSRed }, Cmd.none )


unlockCurrentDocument : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
unlockCurrentDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Cmd.none )

        Just doc_ ->
            let
                doc : Document
                doc =
                    { doc_ | currentEditor = Nothing }
            in
            ( { model
                | userMessage = Nothing
                , messages = Message.make "Document unlocked" MSGreen
                , currentDocument = Just doc
                , documentDirty = False
                , documents = Util.updateDocumentInList doc model.documents
              }
            , Cmd.batch
                [ sendToBackend (SaveDocument doc)
                , sendToBackend (Narrowcast (Util.currentUsername model.currentUser) doc)
                ]
            )


lockDocument : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
lockDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Cmd.none )

        Just doc_ ->
            if doc_.currentEditor == Nothing then
                let
                    currentUsername =
                        Util.currentUsername model.currentUser

                    doc =
                        { doc_ | currentEditor = Just currentUsername }
                in
                ( { model
                    | currentDocument = Just doc
                    , messages = Message.make "Document is locked" MSGreen
                    , documents = Util.updateDocumentInList doc model.documents
                    , documentDirty = False
                  }
                , Cmd.batch
                    [ sendToBackend (SaveDocument doc)
                    , sendToBackend (Narrowcast currentUsername doc)
                    ]
                )

            else
                ( { model | messages = [ { txt = "Document is locked already", status = MSRed } ] }, Cmd.none )


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


openEditor : Document -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
openEditor doc model =
    -- model |> join (openEditor_ doc) lockCurrentDocument
    openEditor_ doc model


openEditor_ : Document -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
openEditor_ doc model =
    let
        updatedDoc =
            { doc | status = Document.DSNormal }
    in
    ( { model
        | showEditor = True
        , sourceText = doc.content
        , initialText = ""
        , currentDocument = Just updatedDoc
      }
    , Cmd.batch [ Frontend.Cmd.setInitialEditorContent 20 ]
    )



-- |> requestLock doc
----|> requestUnlockPreviousThenLockCurrent doc SystemCanEdit
--|>
--|> batch


closeEditor : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
closeEditor model =
    let
        mCurrentEditor : Maybe String
        mCurrentEditor =
            model.currentDocument |> Maybe.andThen .currentEditor

        mCurrentUsername : Maybe String
        mCurrentUsername =
            model.currentUser |> Maybe.map .username

        updatedDoc =
            Maybe.map (\doc -> { doc | status = Document.DSReadOnly }) model.currentDocument

        cmd =
            case updatedDoc of
                Nothing ->
                    Cmd.none

                Just doc ->
                    sendToBackend (SaveDocument doc)
    in
    if mCurrentEditor == mCurrentUsername then
        { model | currentDocument = updatedDoc } |> join (\m -> ( { m | initialText = "", popupState = NoPopup, showEditor = False }, Cmd.none )) unlockCurrentDocument

    else
        ( { model | currentDocument = updatedDoc, initialText = "", popupState = NoPopup, showEditor = False }, cmd )



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


handleSignIn model =
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
            Compiler.DifferentialParser.init doc.language doc.content

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


updateCurrentDocument : Document -> FrontendModel -> FrontendModel
updateCurrentDocument doc model =
    { model | currentDocument = Just doc }



-- SAVE DOCUMENT TOOLS
-- proceedIfDocStatusOK : FrontendModel -> FrontendMsg -> (Document -> FrontendModel -> (FrontendModel, Cmd FrontendMsg)) -> (FrontendModel, Cmd FrontendMsg)
--proceedIfDocStatusOK model doc func =
--    case doc.status of
--                    Document.DSSoftDelete ->
--                        ( model, Cmd.none )
--
--                    Document.DSReadOnly ->
--                        ( model, Cmd.none )
--
--                    Document.DSNormal ->


preserveCurrentDocument model =
    -- TODO: use this function!
    case model.currentDocument of
        Nothing ->
            Cmd.none

        Just doc ->
            case doc.status of
                Document.DSSoftDelete ->
                    Cmd.none

                Document.DSReadOnly ->
                    Cmd.none

                Document.DSNormal ->
                    saveDocumentToBackend { doc | content = model.sourceText }


saveDocumentToBackend : Document.Document -> Cmd FrontendMsg
saveDocumentToBackend doc =
    case doc.status of
        Document.DSSoftDelete ->
            sendToBackend (SaveDocument doc)

        Document.DSReadOnly ->
            sendToBackend (SaveDocument doc)

        Document.DSNormal ->
            sendToBackend (SaveDocument doc)


saveCurrentDocumentToBackend : Maybe Document.Document -> Cmd FrontendMsg
saveCurrentDocumentToBackend mDoc =
    case mDoc of
        Nothing ->
            Cmd.none

        Just doc ->
            case doc.status of
                Document.DSSoftDelete ->
                    Cmd.none

                Document.DSReadOnly ->
                    Cmd.none

                Document.DSNormal ->
                    sendToBackend (SaveDocument doc)



-- SORT
