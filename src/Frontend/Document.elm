module Frontend.Document exposing
    ( addDocToCurrentUser
    , changeLanguage
    , deleteDocFromCurrentUser
    , gotIncludedUserData
    , hardDeleteAll
    , makeBackup
    , makeSmartDocCommand
    , postProcessDocument
    , prepareMasterDocument
    , receivedDocument
    , receivedDocuments
    , receivedNewDocument
    , receivedPublicDocuments
    , saveDocumentToBackend
    , updateDoc
    )

import BoundedDeque exposing (BoundedDeque)
import CollaborativeEditing.NetworkModel as NetworkModel
import Compiler.ASTTools
import Compiler.DifferentialParser
import Dict exposing (Dict)
import Docs
import Document exposing (Document)
import Effect.Browser.Navigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera exposing (sendToBackend)
import ExtractInfo
import Frontend.Cmd
import IncludeFiles
import Message
import Parser.Language
import Predicate
import Types exposing (DocumentDeleteState(..), DocumentHandling(..), FrontendModel, FrontendMsg(..), MessageStatus(..), PhoneMode(..), PopupState(..), ToBackend(..))
import User exposing (User)
import Util
import View.Utility


hardDeleteAll : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
hardDeleteAll model =
    case model.currentMasterDocument of
        Nothing ->
            ( model, Command.none )

        Just masterDoc ->
            if masterDoc.title /= "Deleted Docs" then
                ( model, Command.none )

            else
                let
                    ids =
                        masterDoc.content
                            |> String.split "\n"
                            |> List.filter (\line -> String.left 10 line == "| document")
                            |> List.map (\line -> String.trim (String.dropLeft 10 line))

                    newMasterDoc =
                        { masterDoc | content = "| title\nDeleted Docs\n\n" }

                    documents =
                        List.filter (\doc -> not (List.member doc.id ids)) model.documents
                in
                ( { model
                    | documents = documents
                    , currentMasterDocument =
                        Just newMasterDoc
                  }
                    |> postProcessDocument Docs.deleteDocsRemovedForever
                , Effect.Lamdera.sendToBackend (Types.DeleteDocumentsWithIds ids)
                )


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


updateDoc : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateDoc model str =
    -- This is the only route to function updateDoc, updateDoc_
    if Predicate.documentIsMineOrIAmAnEditor model.currentDocument model.currentUser then
        updateDoc1 model str

    else
        ( model, Command.none )


updateDoc1 : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateDoc1 model str =
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
            if String.left 1 provisionalTitle == "|" && doc.language == Parser.Language.MicroLaTeXLang then
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


changeLanguage : Types.FrontendModel -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
changeLanguage model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            let
                newDocument =
                    { doc | language = model.language }
            in
            ( model
            , Effect.Lamdera.sendToBackend (Types.SaveDocument model.currentUser newDocument)
            )
                |> (\( m, c ) -> ( postProcessDocument newDocument m, c ))


makeBackup : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
makeBackup model =
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
                ( model, Effect.Lamdera.sendToBackend (Types.InsertDocument user newDocument) )

            else
                ( model, Command.none )


gotIncludedUserData : Types.FrontendModel -> Document -> List ( String, String ) -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
gotIncludedUserData model doc listOfData =
    let
        includedContent =
            List.foldl (\( tag, content ) acc -> Dict.insert tag content acc) model.includedContent listOfData

        updateEditRecord_ : Dict.Dict String String -> Document.Document -> FrontendModel -> FrontendModel
        updateEditRecord_ inclusionData doc_ model_ =
            updateEditRecord inclusionData doc_ model_
    in
    ( { model | includedContent = includedContent } |> (\m -> updateEditRecord_ includedContent doc m)
    , Command.none
    )


receivedDocument : Types.FrontendModel -> DocumentHandling -> Document -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
receivedDocument model documentHandling doc =
    case documentHandling of
        StandardHandling ->
            handleAsStandardReceivedDocument model doc

        KeepMasterDocument masterDoc ->
            handleKeepingMasterDocument model masterDoc doc

        HandleSharedDocument username ->
            handleSharedDocument model username doc

        PinnedDocumentList ->
            handleAsStandardReceivedDocument model doc

        HandleAsManual ->
            handleReceivedDocumentAsManual model doc


receivedNewDocument model doc =
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
    , Command.batch [ Util.delay 40 (Types.SetDocumentAsCurrent StandardHandling doc), Frontend.Cmd.setInitialEditorContent 20, View.Utility.setViewPortToTop model.popupState ]
    )


receivedPublicDocuments model publicDocuments =
    case List.head publicDocuments of
        Nothing ->
            ( { model | publicDocuments = publicDocuments }, Command.none )

        Just doc ->
            let
                ( currentMasterDocument, newEditRecord, getFirstDocumentCommand ) =
                    prepareMasterDocument model doc

                -- TODO: fix this
                filesToInclude =
                    IncludeFiles.getData doc.content

                loadCmd =
                    case List.isEmpty filesToInclude of
                        True ->
                            Command.none

                        False ->
                            Effect.Lamdera.sendToBackend (Types.GetIncludedFiles doc filesToInclude)
            in
            ( { model
                | currentMasterDocument = currentMasterDocument
                , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
                , currentDocument = Just doc
                , editRecord = newEditRecord
                , publicDocuments = publicDocuments
              }
            , Command.batch [ loadCmd, getFirstDocumentCommand ]
            )


receivedDocuments model documentHandling documents =
    case List.head documents of
        Nothing ->
            -- ( model, sendToBackend (FetchDocumentById DelayedHandling Config.notFoundDocId) )
            ( model, Command.none )

        Just doc ->
            case documentHandling of
                PinnedDocumentList ->
                    ( { model | pinnedDocuments = List.map Document.toDocInfo documents, currentDocument = Just doc }
                    , Command.none
                    )

                _ ->
                    ( { model | documents = documents, currentDocument = Just doc } |> postProcessDocument doc
                    , Command.none
                    )


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
                        sendToBackend (Types.MakeCollection doc.title currentUserName_ ("folder:" ++ tag))

            else
                Command.none


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


updateEditRecord : Dict String String -> Document -> FrontendModel -> FrontendModel
updateEditRecord inclusionData doc model =
    { model | editRecord = Compiler.DifferentialParser.init inclusionData doc.language doc.content }


saveDocumentToBackend : Maybe User -> Document.Document -> Command FrontendOnly ToBackend FrontendMsg
saveDocumentToBackend currentUser doc =
    case doc.status of
        Document.DSSoftDelete ->
            Command.none

        Document.DSReadOnly ->
            Command.none

        Document.DSCanEdit ->
            Effect.Lamdera.sendToBackend (SaveDocument currentUser doc)
