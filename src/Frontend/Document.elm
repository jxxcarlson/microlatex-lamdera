module Frontend.Document exposing
    ( changeLanguage
    , makeBackup
    , updateDoc
    )

import Docs
import Document
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Frontend.Update
import Lamdera
import Predicate
import Types


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
