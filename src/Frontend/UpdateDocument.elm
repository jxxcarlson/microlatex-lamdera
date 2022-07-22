module Frontend.UpdateDocument exposing (setDocumentStatus)

import Document
import Effect.Command exposing (Command, FrontendOnly)
import Frontend.Document
import Frontend.Update
import Types


setDocumentStatus : Types.FrontendModel -> Document.DocStatus -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
setDocumentStatus model status =
    case model.currentDocument of
        Nothing ->
            ( model, Effect.Command.none )

        Just doc ->
            let
                updatedDoc =
                    { doc | status = status }

                documents =
                    Document.updateDocumentInList updatedDoc model.documents
            in
            ( { model | currentDocument = Just updatedDoc, documentDirty = False, documents = documents }, Frontend.Document.saveDocumentToBackend model.currentUser updatedDoc )
