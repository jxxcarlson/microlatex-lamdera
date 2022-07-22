module Backend.Document exposing (createDocumentAtBackend, getMostRecentUserDocuments)

import Dict
import Document exposing (Document)
import DocumentTools
import Maybe.Extra
import Token
import Types exposing (BackendModel, DocumentDict, UsersDocumentsDict)
import User exposing (User)


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
