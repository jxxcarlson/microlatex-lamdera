module Backend.NetworkModel exposing (processEvent)

import CollaborativeEditing.NetworkModel exposing (EditEvent)
import Deque
import Dict
import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Types exposing (AbstractDict, BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentDict, DocumentHandling(..), MessageStatus(..), ToFrontend(..), UsersDocumentsDict)


processEvent : EditEvent -> BackendModel -> ( BackendModel, Cmd BackendMsg )
processEvent editEvent model =
    ( model, processEventCmd model.sharedDocumentDict editEvent )


processEventCmd : Types.SharedDocumentDict -> EditEvent -> Cmd BackendMsg
processEventCmd sharedDocumentDict event =
    case Dict.get event.docId sharedDocumentDict of
        Nothing ->
            Cmd.none

        Just sharedDoc ->
            Cmd.batch (List.foldl (\editor cmds -> cmdOfEditor editor event :: cmds) [] sharedDoc.currentEditors)


cmdOfEditor : { a | clientId : ClientId } -> EditEvent -> Cmd BackendMsg
cmdOfEditor editor event =
    sendToFrontend editor.clientId (ProcessEvent event)
