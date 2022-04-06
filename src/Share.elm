module Share exposing (narrowCast)

import Dict
import Document
import Lamdera exposing (ClientId)
import Types


type alias Username =
    String


{-| Send the document to all the users listed in document.share who have active connections.
-}
narrowCast : Document.Document -> Types.ConnectionDict -> List (Cmd Types.ToFrontend)
narrowCast document connectionDict =
    case document.share of
        Document.Private ->
            []

        Document.Share { editors, readers } ->
            let
                usernames =
                    editors ++ readers

                clientIds =
                    getClientIds usernames connectionDict
            in
            List.map (\clientId -> Lamdera.sendToFrontend clientId (Types.SendDocument Types.SystemReadOnly document)) clientIds


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
