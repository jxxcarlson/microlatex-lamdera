module Share exposing (narrowCast)

import Dict
import Document
import Lamdera exposing (ClientId)
import Types


type alias Username =
    String


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
