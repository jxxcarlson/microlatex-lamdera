module Frontend.CurrentDocument exposing (set, setDocumentAsCurrent, setDocumentInPhoneAsCurrent, setWithId)

import CollaborativeEditing.NetworkModel
import Compiler.ASTTools
import Compiler.Acc
import Document exposing (Document)
import Effect.Browser.Navigation
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera exposing (sendToBackend)
import Frontend.Document
import Frontend.Editor
import IncludeFiles
import Markup
import Message
import Predicate
import Types
    exposing
        ( DocumentHandling(..)
        , FrontendModel
        , FrontendMsg
        , MessageStatus(..)
        , PhoneMode(..)
        , ToBackend
        )
import User exposing (User)
import Util
import View.Utility


setWithId : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setWithId model id =
    case Document.documentFromListViaId id model.documents of
        Nothing ->
            ( model, Effect.Command.none )

        Just doc ->
            ( Frontend.Document.postProcessDocument doc model, Effect.Command.none )


set : FrontendModel -> Types.DocumentHandling -> Document -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
set model handling document =
    case model.currentDocument of
        Nothing ->
            setDocumentAsCurrent Effect.Command.none model document handling

        Just currentDocument ->
            handleCurrentDocumentChange model currentDocument document


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


setDocumentAsCurrent : Command FrontendOnly ToBackend FrontendMsg -> FrontendModel -> Document.Document -> DocumentHandling -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setDocumentAsCurrent cmd model doc permissions =
    -- TODO: A
    let
        filesToInclude =
            IncludeFiles.getData doc.content

        oldCurrentDocument =
            model.currentDocument
                |> User.mRemoveEditor model.currentUser
                |> Maybe.map Frontend.Editor.setToReadOnlyIfNoEditors

        ( updateOldCurrentDocCmd, newModel ) =
            case oldCurrentDocument of
                Nothing ->
                    ( Effect.Command.none, model )

                Just oldCurrentDoc_ ->
                    ( sendToBackend (Types.SaveDocument model.currentUser oldCurrentDoc_), { model | documents = Document.updateDocumentInList oldCurrentDoc_ model.documents } )
    in
    case List.isEmpty filesToInclude of
        True ->
            setDocumentAsCurrent_ (Effect.Command.batch [ updateOldCurrentDocCmd ]) newModel doc permissions

        False ->
            setDocumentAsCurrent_ (Effect.Command.batch [ updateOldCurrentDocCmd, cmd, Effect.Lamdera.sendToBackend (Types.GetIncludedFiles doc filesToInclude) ]) newModel doc permissions


setDocumentAsCurrent_ : Command FrontendOnly ToBackend FrontendMsg -> FrontendModel -> Document.Document -> DocumentHandling -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setDocumentAsCurrent_ cmd model doc permissions =
    case model.currentUser of
        Nothing ->
            let
                newModel =
                    Frontend.Document.postProcessDocument doc model
            in
            ( { newModel | currentDocument = Just doc }, Effect.Command.none )

        Just currentUser ->
            let
                -- For now, loc the doc in all cases
                currentUserName_ =
                    currentUser.username

                smartDocCommand =
                    Frontend.Document.makeSmartDocCommand doc model.allowOpenFolder currentUserName_

                --    Compiler.DifferentialParser.init model.includedContent doc.language doc.content
                errorMessages : List Types.Message
                errorMessages =
                    Message.make (newEditRecord.messages |> String.join "; ") MSYellow

                ( currentMasterDocument, newEditRecord, getFirstDocumentCommand ) =
                    Frontend.Document.prepareMasterDocument model doc

                ( readers, editors ) =
                    View.Utility.getReadersAndEditors (Just doc)

                newCurrentUser =
                    Frontend.Document.addDocToCurrentUser model doc

                newDocumentStatus =
                    if doc.status == Document.DSSoftDelete then
                        Document.DSSoftDelete

                    else if Predicate.documentIsMineOrSharedToMe (Just doc) model.currentUser && model.showEditor then
                        Document.DSCanEdit

                    else
                        Document.DSReadOnly

                updatedDoc =
                    { doc | status = newDocumentStatus }
                        |> Util.applyIf model.showEditor (Frontend.Editor.addUserToCurrentEditorsOfDocument model.currentUser)
            in
            ( { model
                | currentDocument = Just updatedDoc
                , oTDocument = { docId = updatedDoc.id, cursor = 0, content = updatedDoc.content }
                , selectedSlug = Document.getSlug updatedDoc
                , currentMasterDocument = currentMasterDocument
                , networkModel = CollaborativeEditing.NetworkModel.init (CollaborativeEditing.NetworkModel.initialServerState doc.id (User.currentUserId model.currentUser) doc.content)
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
            , Effect.Command.batch
                [ View.Utility.setViewPortToTop model.popupState
                , Effect.Command.batch [ getFirstDocumentCommand, cmd, Effect.Lamdera.sendToBackend (Types.SaveDocument model.currentUser updatedDoc) ]
                , Effect.Browser.Navigation.pushUrl model.key ("/c/" ++ doc.id)
                , smartDocCommand
                ]
            )


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
        setDocumentAsCurrent (Effect.Lamdera.sendToBackend (Types.SaveDocument model.currentUser updatedDoc)) newModel document StandardHandling

    else if currentDocument.status == Document.DSCanEdit then
        let
            updatedDoc =
                { currentDocument | status = Document.DSReadOnly }

            newModel =
                { model | selectedSlug = Document.getSlug currentDocument, documents = Document.updateDocumentInList updatedDoc model.documents, language = document.language }
        in
        setDocumentAsCurrent (Effect.Lamdera.sendToBackend (Types.SaveDocument model.currentUser updatedDoc)) newModel document StandardHandling

    else
        setDocumentAsCurrent Effect.Command.none model document StandardHandling
