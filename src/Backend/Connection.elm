module Backend.Connection exposing
    ( getConnectionData
    , getUsersAndOnlineStatus
    , getUsersAndOnlineStatus_
    , removeSessionClient
    , removeSessionFromDict
    )

import Authentication
import Backend.Document
import Config
import Dict
import Document
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import List.Extra
import Maybe.Extra
import Share
import Types exposing (BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentHandling(..), ToFrontend(..))


getConnectionData : BackendModel -> List String
getConnectionData model =
    model.connectionDict
        |> Dict.toList
        |> List.map (\( u, data ) -> u ++ ":: " ++ String.fromInt (List.length data) ++ " :: " ++ connectionDataListToString data)


truncateMiddle : Int -> Int -> String -> String
truncateMiddle dropBoth dropRight str =
    String.left dropBoth str ++ "..." ++ String.right dropBoth (String.dropRight dropRight str)


connectionDataListToString : List Types.ConnectionData -> String
connectionDataListToString list =
    list |> List.map connectionDataToString |> String.join "; "


connectionDataToString : Types.ConnectionData -> String
connectionDataToString { session, client } =
    "(" ++ truncateMiddle 2 0 (Effect.Lamdera.sessionIdToString session) ++ ", " ++ truncateMiddle 2 2 (Effect.Lamdera.clientIdToString client) ++ ")"


getUsersAndOnlineStatus_ : Authentication.AuthenticationDict -> ConnectionDict -> List ( String, Int )
getUsersAndOnlineStatus_ authenticationDict connectionDict =
    let
        isConnected username =
            case Dict.get username connectionDict of
                Nothing ->
                    0

                Just data ->
                    List.length data
    in
    List.map (\u -> ( u, isConnected u )) (Dict.keys authenticationDict)


removeSessionClient : BackendModel -> SessionId -> ClientId -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
removeSessionClient model sessionId clientId =
    case getConnectedUser clientId model.connectionDict of
        Nothing ->
            ( { model | connectionDict = removeSessionFromDict sessionId clientId model.connectionDict }, Command.none )

        Just username ->
            let
                connectionDict =
                    removeSessionFromDict sessionId clientId model.connectionDict

                activeSharedDocIds =
                    Share.activeDocumentIdsSharedByMe username model.sharedDocumentDict |> List.map .id

                documents : List Document.Document
                documents =
                    List.foldl (\id list -> Dict.get id model.documentDict :: list) [] activeSharedDocIds
                        |> Maybe.Extra.values
                        |> List.map (\doc -> Share.unshare doc)

                pushSignOutDocCmd : Command BackendOnly ToFrontend BackendMsg
                pushSignOutDocCmd =
                    Backend.Document.fetchDocumentByIdCmd model clientId Config.signOutDocumentId StandardHandling

                notifications =
                    Effect.Lamdera.broadcast (GotUsersWithOnlineStatus (getUsersAndOnlineStatus_ model.authenticationDict connectionDict)) :: List.map (\doc -> Share.narrowCast clientId doc connectionDict) documents

                updatedModel =
                    Backend.Document.setDocumentsToReadOnlyWithUserName username model
            in
            ( { updatedModel
                | sharedDocumentDict = Dict.map Share.removeUserFromSharedDocument model.sharedDocumentDict
                , connectionDict = connectionDict
              }
            , Command.batch <| pushSignOutDocCmd :: notifications
            )


removeSessionFromDict : SessionId -> ClientId -> ConnectionDict -> ConnectionDict
removeSessionFromDict sessionId clientId connectionDict =
    connectionDict
        |> Dict.toList
        |> removeSessionFromList sessionId clientId
        |> Dict.fromList


removeSessionFromList : SessionId -> ClientId -> List ( String, List ConnectionData ) -> List ( String, List ConnectionData )
removeSessionFromList sessionId clientId dataList =
    List.map (\item -> removeItem sessionId clientId item) dataList
        |> List.filter (\( _, list ) -> list /= [])


removeItem : SessionId -> ClientId -> ( String, List ConnectionData ) -> ( String, List ConnectionData )
removeItem sessionId clientId ( username, data ) =
    ( username, removeSession sessionId clientId data )


removeSession : SessionId -> ClientId -> List ConnectionData -> List ConnectionData
removeSession sessionId clientId list =
    List.filter (\datum -> datum /= { session = sessionId, client = clientId }) list


getUsersAndOnlineStatus : BackendModel -> List ( String, Int )
getUsersAndOnlineStatus model =
    getUsersAndOnlineStatus_ model.authenticationDict model.connectionDict


getConnectedUser : ClientId -> ConnectionDict -> Maybe Types.Username
getConnectedUser clientId dict =
    let
        connectionData =
            dict |> Dict.toList |> List.map (\( username, data ) -> ( username, List.map .client data ))

        usernames =
            connectionData
                |> List.filter (\( _, data ) -> List.member clientId data)
                |> List.map (\( a, _ ) -> a)
                |> List.Extra.unique
    in
    List.head usernames
