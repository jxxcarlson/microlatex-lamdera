module Share exposing
    ( activeDocumentIdsSharedByMe
    , canEdit
    , doShare
    , isCurrentlyShared
    , isSharedToMe
    , narrowCast
    , narrowCastIfShared
    , narrowCastToEditorsExceptForSender
    , removeConnectionFromSharedDocumentDict
    , removeEditor
    , resetDocument
    , shareDocument
    , toSharedDocument
    , unshare
    , update
    , updateSharedDocumentDict
    )

import Dict
import Document
import Lamdera exposing (ClientId, sendToBackend, sendToFrontend)
import List.Extra
import Set
import Types
import User
import Util


type alias Username =
    String


removeConnectionFromSharedDocumentDict : ClientId -> Types.SharedDocumentDict -> Types.SharedDocumentDict
removeConnectionFromSharedDocumentDict clientId dict =
    dict
        |> Dict.toList
        |> List.map (\( docId, sharedDoc ) -> ( docId, removeConnectionFromSharedDoc clientId sharedDoc ))
        |> Dict.fromList


removeConnectionFromSharedDoc : ClientId -> Types.SharedDocument -> Types.SharedDocument
removeConnectionFromSharedDoc clientId sharedDoc =
    let
        currentEditors =
            List.filter (\ed -> ed.clientId /= clientId) sharedDoc.currentEditors
    in
    { sharedDoc | currentEditors = currentEditors }


resetDocument : Types.Username -> Types.SharedDocument -> Types.SharedDocument
resetDocument username sharedDocument =
    { sharedDocument | currentEditors = [] }



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
    let
        foo =
            1
    in
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
            { username = username, userId = userId, clientId = clientId }

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


updateSharedDocumentDict : User.User -> Document.Document -> Types.BackendModel -> Types.BackendModel
updateSharedDocumentDict user doc model =
    -- { model | sharedDocumentDict = update user.username user.id doc clientId model.sharedDocumentDict |> Debug.log "UPDATE sharedDocumentDict" }
    { model | sharedDocumentDict = Dict.insert doc.id (toSharedDocument doc) model.sharedDocumentDict }


doShare : Types.FrontendModel -> ( Types.FrontendModel, Cmd Types.FrontendMsg )
doShare model =
    case model.currentDocument of
        Nothing ->
            ( { model | popupState = Types.NoPopup }, Cmd.none )

        Just doc ->
            case model.currentUser of
                Nothing ->
                    ( { model | popupState = Types.NoPopup }, Cmd.none )

                Just user_ ->
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
                                    Cmd.none

                                Just user ->
                                    let
                                        folks =
                                            Set.union (Set.fromList readers) (Set.fromList editors)
                                    in
                                    sendToBackend (Types.UpdateUserWith { user | sharedDocumentAuthors = Set.union folks user.sharedDocumentAuthors })

                        newDocument =
                            { doc | sharedWith = sharedWith }

                        documents =
                            List.Extra.setIf (\d -> d.id == newDocument.id) newDocument model.documents
                    in
                    ( { model | popupState = Types.NoPopup, currentDocument = Just newDocument, documents = documents }
                    , Cmd.batch
                        [ sendToBackend (Types.SaveDocument model.currentUser newDocument)
                        , sendToBackend (Types.UpdateSharedDocumentDict user_ newDocument)
                        , cmdSaveUser
                        ]
                    )


shareDocument : Types.FrontendModel -> ( Types.FrontendModel, Cmd Types.FrontendMsg )
shareDocument model =
    case ( model.currentDocument, model.popupState ) of
        ( Nothing, _ ) ->
            ( model, Cmd.none )

        ( Just doc, Types.NoPopup ) ->
            let
                ( inputReaders, inputEditors ) =
                    ( String.join ", " doc.sharedWith.readers, String.join ", " doc.sharedWith.editors )
            in
            ( { model | popupState = Types.SharePopup, inputReaders = inputReaders, inputEditors = inputEditors }, Cmd.none )

        ( Just doc, _ ) ->
            ( { model | popupState = Types.NoPopup }, Cmd.none )


{-| Send the document to all the users listed in document.share who have active connections,
except to the client calling narrowcast.
-}
narrowCast : ClientId -> Document.Document -> Types.ConnectionDict -> Cmd Types.BackendMsg
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
    Cmd.batch (List.map (\clientId -> Lamdera.sendToFrontend clientId (Types.ReceivedDocument Types.StandardHandling document)) clientIds)


narrowCastIfShared : ClientId -> Types.Username -> Document.Document -> Cmd Types.BackendMsg
narrowCastIfShared clientId username document =
    let
        numberOfDistinctEditors =
            List.map .username document.currentEditorList |> List.Extra.unique |> List.length
    in
    if document.isShared == False || numberOfDistinctEditors <= 1 then
        -- if the document is not shared,
        -- or if there is at most one editor,
        -- then do not narrowcast
        Cmd.none

    else
        let
            -- the editors to whom we send updates be different from the client editor
            editors =
                List.filter (\editor_ -> editor_.clientId /= clientId) document.currentEditorList
        in
        List.map (\editor -> sendToFrontend editor.clientId (Types.ReceivedDocument (Types.HandleSharedDocument username) document)) editors |> Cmd.batch


narrowCastToEditorsExceptForSender : Username -> Document.Document -> Types.ConnectionDict -> Cmd Types.BackendMsg
narrowCastToEditorsExceptForSender sendersName document connectionDict =
    let
        _ =
            Debug.log "narrowCast (sender, others)" ( sendersName, usernames )

        usernames =
            case document.author of
                Nothing ->
                    document.sharedWith.editors |> List.filter (\name -> name /= sendersName && name /= "")

                Just author ->
                    author :: document.sharedWith.editors |> List.filter (\name -> name /= sendersName && name /= "")

        clientIds =
            getClientIds usernames connectionDict |> Debug.log "CLIENTS"
    in
    Cmd.batch (List.map (\clientId -> Lamdera.sendToFrontend clientId (Types.ReceivedDocument (Types.HandleSharedDocument sendersName) document)) clientIds)


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
