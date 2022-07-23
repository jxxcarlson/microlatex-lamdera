module Backend.Search exposing
    ( byAuthorAndKey
    , byKey_
    , findDocumentByAuthorAndKey
    , findDocumentByAuthorAndKey_
    , getUserDocumentsForAuthor
    , publicByKey
    , searchForDocuments
    )

import Authentication
import Config
import Dict
import Document exposing (Document)
import DocumentTools
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId)
import Maybe.Extra
import Predicate
import Types exposing (BackendModel, BackendMsg, DocumentHandling(..), ToFrontend(..))
import User exposing (User)


publicByKey : Types.SortMode -> Int -> Maybe String -> String -> BackendModel -> List Document.Document
publicByKey sortMode limit mUsername key model =
    byKey_ key model
        |> List.filter (\doc -> doc.public || Predicate.isSharedToMe_ mUsername doc)
        |> DocumentTools.sort sortMode
        |> List.take limit


byKey_ : String -> BackendModel -> List Document.Document
byKey_ key model =
    let
        ids =
            Dict.toList model.abstractDict
                |> List.map (\( id, abstr ) -> ( abstr.digest, id ))
                |> List.filter (\( dig, _ ) -> String.contains (String.toLower key) dig)
                |> List.map (\( _, id ) -> id)
    in
    List.foldl (\id acc -> Dict.get id model.documentDict :: acc) [] ids |> Maybe.Extra.values


byKey : Maybe String -> String -> BackendModel -> List Document.Document
byKey maybeUsername key model =
    let
        ids =
            Dict.toList model.abstractDict
                |> List.map (\( id, abstr ) -> ( abstr.digest, id ))
                |> List.filter (\( dig, _ ) -> String.contains (String.toLower key) dig)
                |> List.map (\( _, id ) -> id)
    in
    List.foldl (\id acc -> Dict.get id model.documentDict :: acc) [] ids
        |> Maybe.Extra.values
        |> List.filter (\doc -> doc.author /= Just "" && doc.author == maybeUsername)
        |> List.take Config.maxDocSearchLimit


searchForDocuments : BackendModel -> ClientId -> DocumentHandling -> Maybe User -> String -> ( BackendModel, Command BackendOnly ToFrontend backendMsg )
searchForDocuments model clientId documentHandling currentUser key =
    ( model
    , if String.contains ":user" key then
        Effect.Lamdera.sendToFrontend clientId (ReceivedDocuments documentHandling (byKey (Maybe.map .username currentUser) (stripKey ":user" key) model))

      else
        Command.batch
            [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocuments documentHandling (byKey (Maybe.map .username currentUser) key model))
            , Effect.Lamdera.sendToFrontend clientId (ReceivedPublicDocuments (publicByKey Types.SortAlphabetically Config.maxDocSearchLimit (Maybe.map .username currentUser) key model))
            ]
    )


stripKey str key =
    String.replace str key "" |> String.trim


byAuthorAndKey model clientId key =
    ( model, Effect.Lamdera.sendToFrontend clientId (ReceivedDocuments StandardHandling (byAuthorAndKey_ model key)) )


byAuthorAndKey_ : BackendModel -> String -> List Document.Document
byAuthorAndKey_ model key =
    case String.split "/" key of
        [] ->
            []

        author :: [] ->
            getUserDocumentsForAuthor author model

        author :: firstKey :: _ ->
            getUserDocumentsForAuthor author model |> List.filter (\doc -> List.member ("id:" ++ firstKey) doc.tags)


findDocumentByAuthorAndKey : BackendModel -> ClientId -> Types.DocumentHandling -> String -> String -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
findDocumentByAuthorAndKey model clientId documentHandling authorName searchKey =
    case findDocumentByAuthorAndKey_ model authorName searchKey of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            ( model, Effect.Lamdera.sendToFrontend clientId (ReceivedDocument documentHandling doc) )


findDocumentByAuthorAndKey_ : BackendModel -> String -> String -> Maybe Document
findDocumentByAuthorAndKey_ model authorName searchKey =
    let
        foundDocs =
            getUserDocumentsForAuthor authorName model |> List.filter (\doc -> List.member searchKey doc.tags)
    in
    List.head foundDocs


getUserDocumentsForAuthor : String -> BackendModel -> List Document.Document
getUserDocumentsForAuthor author model =
    case Authentication.userIdFromUserName author model.authenticationDict of
        Nothing ->
            []

        Just userId ->
            case Dict.get userId model.usersDocumentsDict of
                Nothing ->
                    []

                Just usersDocIds ->
                    List.map (\id -> Dict.get id model.documentDict) usersDocIds |> Maybe.Extra.values
