module Share exposing
    ( activeDocumentIdsSharedByMe
    , canEdit
    , createShareDocumentDict
    , doShare
    , insert
    , isCurrentlyShared
    , isSharedToMe
    , narrowCast
    , resetDocument
    , shareDocument
    , unshare
    , updateSharedDocumentDict
    )

import Dict
import Document
import Lamdera exposing (ClientId, sendToBackend)
import List.Extra
import Set
import Types
import User


type alias Username =
    String


resetDocument : Types.Username -> Types.SharedDocument -> Types.SharedDocument
resetDocument username sharedDocument =
    { sharedDocument | currentEditors = [] }



-- TODO: examine


getSharedDocument : Document.Document -> Types.SharedDocument
getSharedDocument doc =
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
    List.member username (doc.currentEditors |> List.map .username)


isMineAndNotShared : String -> Document.Document -> Bool
isMineAndNotShared username doc =
    doc.sharedWith == { readers = [], editors = [] } && Just username == doc.author


isSharedToMeStrict : String -> Document.Document -> Bool
isSharedToMeStrict username doc =
    List.member username doc.sharedWith.editors && isSharedByMe username doc


isSharedToMe : String -> Document.SharedWith -> Bool
isSharedToMe username sharedWith =
    List.member username sharedWith.readers || List.member username sharedWith.editors


insert : Document.Document -> Types.SharedDocumentDict -> Types.SharedDocumentDict
insert doc dict =
    if doc.sharedWith.readers == [] && doc.sharedWith.editors == [] then
        dict

    else
        Dict.insert doc.id (getSharedDocument doc) dict


createShareDocumentDict : Types.DocumentDict -> Types.SharedDocumentDict
createShareDocumentDict documentDict =
    documentDict
        |> Dict.values
        |> List.foldl (\doc dict -> insert doc dict) Dict.empty


updateSharedDocumentDict : Document.Document -> Types.BackendModel -> Types.BackendModel
updateSharedDocumentDict doc model =
    { model | sharedDocumentDict = insert doc model.sharedDocumentDict }


doShare model =
    case model.currentDocument of
        Nothing ->
            ( { model | popupState = Types.NoPopup }, Cmd.none )

        Just doc ->
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
                [ sendToBackend (Types.SaveDocument newDocument)
                , sendToBackend (Types.UpdateSharedDocumentDict newDocument)
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


{-| Send the document to all the users listed in document.share who have active connections.
-}
narrowCast : Username -> Document.Document -> Types.ConnectionDict -> Cmd Types.BackendMsg
narrowCast sendersName document connectionDict =
    let
        usernames =
            case document.author of
                Nothing ->
                    document.sharedWith.editors ++ document.sharedWith.readers |> List.filter (\name -> name /= sendersName && name /= "")

                Just author ->
                    author :: (document.sharedWith.editors ++ document.sharedWith.readers) |> List.filter (\name -> name /= sendersName && name /= "")

        clientIds =
            getClientIds usernames connectionDict
    in
    Cmd.batch (List.map (\clientId -> Lamdera.sendToFrontend clientId (Types.ReceivedDocument Types.StandardHandling document)) clientIds)


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
    { doc | currentEditors = [] }



-- TODO: ?? OK
