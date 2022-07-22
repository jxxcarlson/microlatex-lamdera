module Backend.Document exposing
    ( createDocumentAtBackend
    , fetchDocumentByIdCmd
    , getMostRecentUserDocuments
    , setDocumentsToReadOnlyWithUserName
    )

import Dict
import Document exposing (Document)
import DocumentTools
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId)
import Maybe.Extra
import Token
import Types exposing (BackendModel, BackendMsg, DocumentDict, ToFrontend, UsersDocumentsDict)
import User exposing (User)
import Util


{-| Apply a function to all documents for a given user (defined by his user id) and persist the result in the backend model
-}
applyToUsersDocuments : Types.UserId -> (Document -> Document) -> BackendModel -> BackendModel
applyToUsersDocuments userId f model =
    applyToDocuments (Dict.get userId model.usersDocumentsDict |> Maybe.withDefault []) f model


{-| Apply a function to all documents defined by a list of documents and persist the result in the backend model
-}
applyToDocuments : List Types.DocId -> (Document -> Document) -> BackendModel -> BackendModel
applyToDocuments idList f model =
    let
        oldDocumentDict =
            model.documentDict

        newDocumentDict =
            List.foldl (\id dict -> Dict.update id (Util.liftToMaybe f) dict) oldDocumentDict idList
    in
    { model | documentDict = newDocumentDict }


setDocumentsToReadOnlyWithUserName : Types.Username -> BackendModel -> BackendModel
setDocumentsToReadOnlyWithUserName username model =
    case Dict.get username model.authenticationDict of
        Nothing ->
            model

        Just { user } ->
            setUsersDocumentsToReadOnly user.id model


setUsersDocumentsToReadOnly : Types.UserId -> BackendModel -> BackendModel
setUsersDocumentsToReadOnly userId model =
    applyToUsersDocuments userId (\doc -> { doc | status = Document.DSReadOnly }) model


fetchDocumentByIdCmd : BackendModel -> ClientId -> String -> Types.DocumentHandling -> Command BackendOnly ToFrontend BackendMsg
fetchDocumentByIdCmd model clientId docId documentHandling =
    case Dict.get docId model.documentDict of
        Nothing ->
            Command.none

        Just document ->
            Effect.Lamdera.sendToFrontend clientId (Types.ReceivedDocument documentHandling document)


createDocumentAtBackend : Maybe User -> Document -> BackendModel -> BackendModel
createDocumentAtBackend maybeCurrentUser doc_ model =
    let
        idTokenData =
            Token.get model.randomSeed

        authorIdTokenData =
            Token.get idTokenData.seed

        doc =
            { doc_
                | id = "id-" ++ idTokenData.token
                , created = model.currentTime
                , modified = model.currentTime
            }

        documentDict =
            Dict.insert ("id-" ++ idTokenData.token) doc model.documentDict

        authorIdDict =
            Dict.insert ("au-" ++ authorIdTokenData.token) doc.id model.authorIdDict

        usersDocumentsDict =
            case maybeCurrentUser of
                Nothing ->
                    model.usersDocumentsDict

                Just user ->
                    let
                        oldIdList =
                            Dict.get user.id model.usersDocumentsDict |> Maybe.withDefault []
                    in
                    Dict.insert user.id (doc.id :: oldIdList) model.usersDocumentsDict
    in
    { model
        | randomSeed = authorIdTokenData.seed
        , documentDict = documentDict
        , authorIdDict = authorIdDict
        , usersDocumentsDict = usersDocumentsDict
    }


getMostRecentUserDocuments : Types.SortMode -> Int -> User -> UsersDocumentsDict -> DocumentDict -> List Document.Document
getMostRecentUserDocuments sortMode limit user usersDocumentsDict documentDict =
    case Dict.get user.id usersDocumentsDict of
        Nothing ->
            []

        Just docIds ->
            List.foldl (\id acc -> Dict.get id documentDict :: acc) [] docIds
                |> Maybe.Extra.values
                |> DocumentTools.sort Types.SortByMostRecent
                |> List.take limit
                |> DocumentTools.sort sortMode
