module Share exposing
    ( createShareDocumentDict
    , isSharedToMe
    , narrowCast
    , shareDocument
    )

import Dict
import Document
import Lamdera exposing (ClientId)
import Types


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
            Cmd.batch (List.map (\clientId -> Lamdera.sendToFrontend clientId (Types.SendDocument Types.SystemCanEdit document)) clientIds)


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
