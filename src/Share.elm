module Share exposing
    ( activeDocumentIdsSharedByMe
    , canEdit
    , doShare
    , isCurrentlyShared
    , isSharedToMe
    , narrowCast
    , narrowCastIfShared
    , narrowCastToEditorsExceptForSender
    , removeEditor
    , removeUserFromSharedDocument
    , removeUserFromSharedDocumentDict
    , shareDocument
    , toSharedDocument
    , unshare
    , update
    , updateSharedDocumentDict
    )

import Dict
import Document
import Effect.Command as Command exposing (Command)
import Effect.Lamdera exposing (ClientId)
import List.Extra
import Maybe.Extra
import Set
import Types
import User
import Util


type alias Username =
    String



--
--removeConnectionFromSharedDocumentDict : ClientId -> Types.SharedDocumentDict -> Types.SharedDocumentDict
--removeConnectionFromSharedDocumentDict clientId dict =
--    dict
--        |> Dict.toList
--        |> List.map (\( docId, sharedDoc ) -> ( docId, removeConnectionFromSharedDoc clientId sharedDoc ))
--        |> Dict.fromList
--
--
--removeConnectionFromSharedDoc : ClientId -> Types.SharedDocument -> Types.SharedDocument
--removeConnectionFromSharedDoc clientId sharedDoc =
--    let
--        currentEditors =
--            List.filter (\ed -> ed.clientId /= clientId) sharedDoc.currentEditors
--    in
--    { sharedDoc | currentEditors = currentEditors }


removeUserFromSharedDocument : Types.Username -> Types.SharedDocument -> Types.SharedDocument
removeUserFromSharedDocument username sharedDocument =
    { sharedDocument | currentEditors = List.filter (\editorData -> editorData.username /= username) sharedDocument.currentEditors }


removeUserFromSharedDocumentDict : Types.Username -> Types.SharedDocumentDict -> Types.SharedDocumentDict
removeUserFromSharedDocumentDict username dict =
    let
        f : String -> Types.SharedDocument -> Types.SharedDocument
        f =
            \_ -> removeUserFromSharedDocument username
    in
    Dict.map f dict



-- TODO: examine


toSharedDocument : Document.Document -> Types.SharedDocument
toSharedDocument doc =
    { title = doc.title
    , id = doc.id
    , author = doc.author
    , share = doc.sharedWith
    , currentEditors = [] -- TODO
    }


canEdit : Maybe User.User -> Maybe Document.Document -> Bool
canEdit currentUser currentDocument =
    case ( currentUser, currentDocument ) of
        ( Just user, Just doc ) ->
            isMineAndNotShared user.username doc || isSharedToMeStrict user.username doc || isSharedByMe user.username doc

        _ ->
            False


isSharedByMe : String -> Document.Document -> Bool
isSharedByMe username doc =
    List.member username (doc.currentEditorList |> List.map .username)


isMineAndNotShared : String -> Document.Document -> Bool
isMineAndNotShared username doc =
    doc.sharedWith == { readers = [], editors = [] } && Just username == doc.author


isSharedToMeStrict : String -> Document.Document -> Bool
isSharedToMeStrict username doc =
    List.member username doc.sharedWith.editors && isSharedByMe username doc


isSharedToMe : String -> Document.SharedWith -> Bool
isSharedToMe username sharedWith =
    List.member username sharedWith.readers || List.member username sharedWith.editors


update : Username -> Types.UserId -> Document.Document -> ClientId -> Types.SharedDocumentDict -> Types.SharedDocumentDict
update username userId doc clientId dict =
    let
        newEditor =
            { username = username, userId = userId, clients = clientId :: (List.map .clients doc.currentEditorList |> List.concat) }

        equal a b =
            a.userId == b.userId

        updater : Types.SharedDocument -> Types.SharedDocument
        updater sharedDoc =
            { sharedDoc | currentEditors = Util.insertInListOrUpdate equal newEditor sharedDoc.currentEditors }
    in
    if doc.sharedWith.readers == [] && doc.sharedWith.editors == [] then
        dict

    else
        Dict.update doc.id (Util.liftToMaybe updater) dict


{-| Remove the editor with given userId from the currentEditor list of the corresponding SharedDoc
-}
removeEditor : Types.UserId -> Document.Document -> Types.SharedDocumentDict -> Types.SharedDocumentDict
removeEditor userId doc dict =
    let
        updater : Types.SharedDocument -> Types.SharedDocument
        updater sharedDoc =
            { sharedDoc | currentEditors = List.filter (\ed -> ed.userId /= userId) sharedDoc.currentEditors }
    in
    if doc.sharedWith.readers == [] && doc.sharedWith.editors == [] then
        dict

    else
        Dict.update doc.id (Util.liftToMaybe updater) dict


updateSharedDocumentDict : Document.Document -> Types.BackendModel -> Types.BackendModel
updateSharedDocumentDict doc model =
    { model | sharedDocumentDict = Dict.insert doc.id (toSharedDocument doc) model.sharedDocumentDict }


doShare : Types.FrontendModel -> ( Types.FrontendModel, Command Command.FrontendOnly Types.ToBackend Types.FrontendMsg )
doShare model =
    case model.currentDocument of
        Nothing ->
            ( { model | popupState = Types.NoPopup }, Command.none )

        Just doc ->
            case model.currentUser of
                Nothing ->
                    ( { model | popupState = Types.NoPopup }, Command.none )

                Just _ ->
                    let
                        readers =
                            model.inputReaders |> String.split "," |> List.map String.trim

                        editors =
                            model.inputEditors |> String.split "," |> List.map String.trim

                        sharedWith =
                            { readers = readers, editors = editors }

                        cmdSaveUser =
                            case model.currentUser of
                                Nothing ->
                                    Command.none

                                Just user ->
                                    let
                                        folks =
                                            Set.union (Set.fromList readers) (Set.fromList editors)
                                    in
                                    Effect.Lamdera.sendToBackend (Types.UpdateUserWith { user | sharedDocumentAuthors = Set.union folks user.sharedDocumentAuthors })

                        newDocument =
                            { doc | sharedWith = sharedWith }

                        documents =
                            List.Extra.setIf (\d -> d.id == newDocument.id) newDocument model.documents
                    in
                    ( { model | popupState = Types.NoPopup, currentDocument = Just newDocument, documents = documents }
                    , Command.batch
                        [ Effect.Lamdera.sendToBackend (Types.SaveDocument model.currentUser newDocument)
                        , Effect.Lamdera.sendToBackend (Types.UpdateSharedDocumentDict newDocument)
                        , cmdSaveUser
                        ]
                    )


shareDocument : Types.FrontendModel -> ( Types.FrontendModel, Command restriction toMsg Types.FrontendMsg )
shareDocument model =
    case ( model.currentDocument, model.popupState ) of
        ( Nothing, _ ) ->
            ( model, Command.none )

        ( Just doc, Types.NoPopup ) ->
            let
                ( inputReaders, inputEditors ) =
                    ( String.join ", " doc.sharedWith.readers, String.join ", " doc.sharedWith.editors )
            in
            ( { model | popupState = Types.SharePopup, inputReaders = inputReaders, inputEditors = inputEditors }, Command.none )

        ( Just _, _ ) ->
            ( { model | popupState = Types.NoPopup }, Command.none )


{-| Send the document to all the users listed in document.share who have active connections,
except to the client calling narrowcast.
-}
narrowCast : ClientId -> Document.Document -> Types.ConnectionDict -> Command Command.BackendOnly Types.ToFrontend Types.BackendMsg
narrowCast requestingClientId document connectionDict =
    let
        usernames =
            case document.author of
                Nothing ->
                    document.sharedWith.editors ++ document.sharedWith.readers |> List.filter (\name -> name /= "")

                --|> List.filter (\name -> name /= sendersName && name /= "")
                Just author ->
                    author :: (document.sharedWith.editors ++ document.sharedWith.readers) |> List.filter (\name -> name /= "")

        --|> List.filter (\name -> name /= sendersName && name /= "")
        clientIds =
            getClientIds usernames connectionDict |> List.filter (\id -> id /= requestingClientId)
    in
    Command.batch (List.map (\clientId -> Effect.Lamdera.sendToFrontend clientId (Types.ReceivedDocument Types.StandardHandling document)) clientIds)


narrowCastIfShared : Types.ConnectionDict -> Types.Username -> Document.Document -> Command Command.BackendOnly Types.ToFrontend Types.BackendMsg
narrowCastIfShared connectionDict username document =
    let
        numberOfDistinctEditors =
            List.map .username document.currentEditorList |> List.Extra.unique |> List.length
    in
    if document.isShared == False || numberOfDistinctEditors <= 1 then
        -- if the document is not shared,
        -- or if there is at most one editor,
        -- then do not narrowcast
        Command.none

    else
        let
            -- the editors to whom we send updates be different from the client editor
            editors =
                List.filter (\editor_ -> editor_.username /= username) document.currentEditorList

            clients =
                clientIdsOfEditors connectionDict editors
        in
        List.map (\client -> Effect.Lamdera.sendToFrontend client (Types.ReceivedDocument (Types.HandleSharedDocument username) document)) clients |> Command.batch


clientIdsOfEditors : Types.ConnectionDict -> List Document.EditorData -> List ClientId
clientIdsOfEditors connectionDict editors =
    List.foldl (\editorName acc -> Dict.get editorName connectionDict :: acc) [] (List.map .username editors)
        |> Maybe.Extra.values
        |> List.concat
        |> List.map .client


narrowCastToEditorsExceptForSender : Username -> Document.Document -> Types.ConnectionDict -> Command Command.BackendOnly Types.ToFrontend Types.BackendMsg
narrowCastToEditorsExceptForSender sendersName document connectionDict =
    let
        usernames =
            case document.author of
                Nothing ->
                    document.sharedWith.editors |> List.filter (\name -> name /= sendersName && name /= "")

                Just author ->
                    author :: document.sharedWith.editors |> List.filter (\name -> name /= sendersName && name /= "")

        clientIds =
            getClientIds usernames connectionDict
    in
    Command.batch (List.map (\clientId -> Effect.Lamdera.sendToFrontend clientId (Types.ReceivedDocument (Types.HandleSharedDocument sendersName) document)) clientIds)


getClientIds : List Username -> Types.ConnectionDict -> List ClientId
getClientIds usernames dict =
    List.foldl (\name list -> addClientIdsForUser name dict list) [] usernames


addClientIdsForUser : Username -> Types.ConnectionDict -> List ClientId -> List ClientId
addClientIdsForUser username dict clientIdList =
    case Dict.get username dict of
        Nothing ->
            clientIdList

        Just data ->
            List.map .client data ++ clientIdList



-- isCurrentlyShared : Document.DocumentId -> Types.SharedDocumentDict -> List {username, userId}
-- isCurrentlyShared : String -> Dict.Dict comparable Types.SharedDocumentDict -> List { username : String, userId : String }


isCurrentlyShared : comparable -> Dict.Dict comparable { a | currentEditors : List b } -> List b
isCurrentlyShared docId dict =
    Dict.get docId dict |> Maybe.map .currentEditors |> Maybe.withDefault []


isAnEditorOf : String -> Types.SharedDocument -> Bool
isAnEditorOf username sharedDocument =
    List.member username (sharedDocument.currentEditors |> List.map .username)


activeDocumentIdsSharedByMe : Types.Username -> Types.SharedDocumentDict -> List Types.SharedDocument
activeDocumentIdsSharedByMe username dict =
    dict |> Dict.toList |> List.filter (\( _, data ) -> isAnEditorOf username data) |> List.map Tuple.second


unshare : Document.Document -> Document.Document
unshare doc =
    { doc | currentEditorList = [] }



-- TODO: ?? OK
