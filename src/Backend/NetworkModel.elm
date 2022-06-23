module Backend.NetworkModel exposing (processEvent)

import CollaborativeEditing.NetworkModel exposing (EditEvent)
import Deque
import Dict
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Types exposing (AbstractDict, BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentDict, DocumentHandling(..), MessageStatus(..), ToFrontend(..), UsersDocumentsDict)


processEvent : EditEvent -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
processEvent editEvent model =
    ( model, processEventCmd model.sharedDocumentDict editEvent )


processEventCmd : Types.SharedDocumentDict -> EditEvent -> Command BackendOnly ToFrontend BackendMsg
processEventCmd sharedDocumentDict event =
    case Dict.get event.docId sharedDocumentDict of
        Nothing ->
            Command.none

        Just sharedDoc ->
            -- Command.none
            let
                clients =
                    List.map .clients sharedDoc.currentEditors |> List.concat
            in
            Command.batch (List.foldl (\clientId cmds -> cmdOfEditor clientId event :: cmds) [] clients)


cmdOfEditor : ClientId -> EditEvent -> Command BackendOnly Types.ToFrontend BackendMsg
cmdOfEditor clientId event =
    Effect.Lamdera.sendToFrontend clientId (ProcessEvent event)
