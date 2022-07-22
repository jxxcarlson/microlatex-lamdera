module Frontend.Document exposing
    ( changeLanguage
    , gotIncludedUserData
    , hardDeleteAll
    , makeBackup
    , receivedDocument
    , receivedNewDocument
    , receivedPublicDocuments
    , setDocumentAsCurrent
    , setDocumentAsCurrentViaId
    , updateDoc
    )

import Compiler.ASTTools
import Compiler.DifferentialParser
import Dict
import Docs
import Document exposing (Document)
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Frontend.Cmd
import Frontend.Update
import IncludeFiles
import Predicate
import Types exposing (DocumentHandling(..), FrontendModel, FrontendMsg, ToBackend)
import Util
import View.Utility


setDocumentAsCurrentViaId : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setDocumentAsCurrentViaId model id =
    case Document.documentFromListViaId id model.documents of
        Nothing ->
            ( model, Effect.Command.none )

        Just doc ->
            ( Frontend.Update.postProcessDocument doc model, Effect.Command.none )


setDocumentAsCurrent : FrontendModel -> Types.DocumentHandling -> Document -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setDocumentAsCurrent model handling document =
    case model.currentDocument of
        Nothing ->
            Frontend.Update.setDocumentAsCurrent Effect.Command.none model document handling

        Just currentDocument ->
            Frontend.Update.handleCurrentDocumentChange model currentDocument document


hardDeleteAll : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
hardDeleteAll model =
    case model.currentMasterDocument of
        Nothing ->
            ( model, Effect.Command.none )

        Just masterDoc ->
            if masterDoc.title /= "Deleted Docs" then
                ( model, Effect.Command.none )

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
                    |> Frontend.Update.postProcessDocument Docs.deleteDocsRemovedForever
                , Effect.Lamdera.sendToBackend (Types.DeleteDocumentsWithIds ids)
                )


updateDoc : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateDoc model str =
    -- This is the only route to function updateDoc, updateDoc_
    if Predicate.documentIsMineOrIAmAnEditor model.currentDocument model.currentUser then
        Frontend.Update.updateDoc model str

    else
        ( model, Effect.Command.none )


changeLanguage : Types.FrontendModel -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
changeLanguage model =
    case model.currentDocument of
        Nothing ->
            ( model, Effect.Command.none )

        Just doc ->
            let
                newDocument =
                    { doc | language = model.language }
            in
            ( model
            , Effect.Lamdera.sendToBackend (Types.SaveDocument model.currentUser newDocument)
            )
                |> (\( m, c ) -> ( Frontend.Update.postProcessDocument newDocument m, c ))


makeBackup : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
makeBackup model =
    case ( model.currentUser, model.currentDocument ) of
        ( Nothing, _ ) ->
            ( model, Effect.Command.none )

        ( _, Nothing ) ->
            ( model, Effect.Command.none )

        ( Just user, Just doc ) ->
            if Just user.username == doc.author then
                let
                    newDocument =
                        Document.makeBackup doc
                in
                ( model, Effect.Lamdera.sendToBackend (Types.InsertDocument user newDocument) )

            else
                ( model, Effect.Command.none )


gotIncludedUserData : Types.FrontendModel -> Document -> List ( String, String ) -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
gotIncludedUserData model doc listOfData =
    let
        includedContent =
            List.foldl (\( tag, content ) acc -> Dict.insert tag content acc) model.includedContent listOfData

        updateEditRecord : Dict.Dict String String -> Document.Document -> FrontendModel -> FrontendModel
        updateEditRecord inclusionData doc_ model_ =
            Frontend.Update.updateEditRecord inclusionData doc_ model_
    in
    ( { model | includedContent = includedContent } |> (\m -> updateEditRecord includedContent doc m)
    , Effect.Command.none
    )


receivedDocument : Types.FrontendModel -> DocumentHandling -> Document -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
receivedDocument model documentHandling doc =
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
    , Effect.Command.batch [ Util.delay 40 (Types.SetDocumentAsCurrent StandardHandling doc), Frontend.Cmd.setInitialEditorContent 20, View.Utility.setViewPortToTop model.popupState ]
    )


receivedPublicDocuments model publicDocuments =
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
                            Effect.Lamdera.sendToBackend (Types.GetIncludedFiles doc filesToInclude)
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
