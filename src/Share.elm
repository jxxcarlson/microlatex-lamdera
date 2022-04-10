module Share exposing
    ( canEdit
    , createShareDocumentDict
    , doShare
    , isSharedToMe
    , narrowCast
    , shareDocument
    , updateSharedDocumentDict
    )

import Dict
import Document
import Lamdera exposing (ClientId, sendToBackend)
import List.Extra
import Types
import User


type alias Username =
    String


getSharedDocument : Document.Document -> Types.SharedDocument
getSharedDocument doc =
    { title = doc.title
    , id = doc.id
    , author = doc.author
    , share = doc.share
    , currentEditor = doc.currentEditor
    }


canEdit : Maybe User.User -> Maybe Document.Document -> Bool
canEdit currentUser currentDocument =
    let
        foo =
            1
    in
    case ( currentUser, currentDocument ) of
        ( Just user, Just doc ) ->
            isMineAndNotShared user.username doc || isSharedToMe user.username doc.share || isSharedByMe user.username doc

        _ ->
            False


isSharedByMe : String -> Document.Document -> Bool
isSharedByMe username doc =
    Just username == doc.currentEditor


isMineAndNotShared : String -> Document.Document -> Bool
isMineAndNotShared username doc =
    doc.share == Document.NotShared && Just username == doc.author


isSharedToMe : String -> Document.Share -> Bool
isSharedToMe username share_ =
    case share_ of
        Document.NotShared ->
            False

        Document.ShareWith { readers, editors } ->
            List.member username readers || List.member username editors


insert : Document.Document -> Types.SharedDocumentDict -> Types.SharedDocumentDict
insert doc dict =
    case doc.share of
        Document.NotShared ->
            dict

        Document.ShareWith _ ->
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

                share =
                    if List.isEmpty readers && List.isEmpty editors then
                        Document.NotShared

                    else
                        Document.ShareWith { readers = readers, editors = editors }

                newDocument =
                    { doc | share = share }

                documents =
                    List.Extra.setIf (\d -> d.id == newDocument.id) newDocument model.documents
            in
            ( { model | popupState = Types.NoPopup, currentDocument = Just newDocument, documents = documents }
            , Cmd.batch [ sendToBackend (Types.SaveDocument newDocument), sendToBackend (Types.UpdateSharedDocumentDict newDocument) ]
            )


shareDocument : Types.FrontendModel -> ( Types.FrontendModel, Cmd Types.FrontendMsg )
shareDocument model =
    case ( model.currentDocument, model.popupState ) of
        ( Nothing, _ ) ->
            ( model, Cmd.none )

        ( Just doc, Types.NoPopup ) ->
            let
                ( inputReaders, inputEditors ) =
                    case doc.share of
                        Document.NotShared ->
                            ( "", "" )

                        Document.ShareWith { readers, editors } ->
                            ( String.join ", " readers, String.join ", " editors )
            in
            ( { model | popupState = Types.SharePopup, inputReaders = inputReaders, inputEditors = inputEditors }, Cmd.none )

        ( Just doc, _ ) ->
            ( { model | popupState = Types.NoPopup }, Cmd.none )


{-| Send the document to all the users listed in document.share who have active connections.
-}
narrowCast : Username -> Document.Document -> Types.ConnectionDict -> Cmd Types.BackendMsg
narrowCast sendersName document connectionDict =
    case document.share of
        Document.NotShared ->
            Cmd.none

        Document.ShareWith { editors, readers } ->
            let
                usernames =
                    case document.author of
                        Nothing ->
                            editors ++ readers |> List.filter (\name -> name /= sendersName && name /= "")

                        Just author ->
                            author :: (editors ++ readers) |> List.filter (\name -> name /= sendersName && name /= "")

                clientIds =
                    getClientIds usernames connectionDict
            in
            Cmd.batch (List.map (\clientId -> Lamdera.sendToFrontend clientId (Types.ReceivedDocument Types.SystemCanEdit document)) clientIds)


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
