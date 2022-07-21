module Frontend.DocumentList exposing
    ( closeCollectionIndex
    , selectDocumentList
    , toggleActiveDocumentList
    , toggleIndexSize
    )

import Effect.Command
import Effect.Lamdera
import Types


selectDocumentList model list =
    let
        cmd =
            if list == Types.SharedDocumentList then
                Effect.Lamdera.sendToBackend (Types.GetSharedDocuments (model.currentUser |> Maybe.map .username |> Maybe.withDefault "(anon)"))

            else if list == Types.PinnedDocs then
                Effect.Lamdera.sendToBackend (Types.SearchForDocuments Types.PinnedDocumentList model.currentUser "pin")

            else
                Effect.Command.none
    in
    ( { model | lastInteractionTime = model.currentTime, documentList = list }, cmd )


toggleIndexSize model =
    case model.maximizedIndex of
        Types.MMyDocs ->
            ( { model | maximizedIndex = Types.MPublicDocs }, Effect.Command.none )

        Types.MPublicDocs ->
            ( { model | maximizedIndex = Types.MMyDocs }, Effect.Command.none )


closeCollectionIndex model =
    ( { model | currentMasterDocument = Nothing }, Effect.Command.none )


toggleActiveDocumentList model =
    case model.currentMasterDocument of
        Nothing ->
            ( { model | activeDocList = Types.Both }, Effect.Command.none )

        Just _ ->
            case model.activeDocList of
                Types.PublicDocsList ->
                    ( { model | activeDocList = Types.PrivateDocsList }, Effect.Command.none )

                Types.PrivateDocsList ->
                    ( { model | activeDocList = Types.PublicDocsList }, Effect.Command.none )

                Types.Both ->
                    ( { model | activeDocList = Types.PrivateDocsList }, Effect.Command.none )
