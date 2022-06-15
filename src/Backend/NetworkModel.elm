module Backend.NetworkModel exposing (processEvent)

import CollaborativeEditing.NetworkModel exposing (EditEvent)
import Deque
import Dict
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Types exposing (AbstractDict, BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentDict, DocumentHandling(..), MessageStatus(..), ToFrontend(..), UsersDocumentsDict)


processEvent : EditEvent -> BackendModel -> ( BackendModel, Command restriction toMsg BackendMsg )
processEvent editEvent model =
    ( model, processEventCmd model.sharedDocumentDict editEvent )


processEventCmd : Types.SharedDocumentDict -> EditEvent -> Command restriction toMsg BackendMsg
processEventCmd sharedDocumentDict event =
    case Dict.get event.docId sharedDocumentDict of
        Nothing ->
            Command.none

        Just sharedDoc ->
            --Cmd.batch (List.foldl (\editor cmds -> cmdOfEditor editor event :: cmds) [] sharedDoc.currentEditors)
            Command.none


cmdOfEditor : { a | clientId : ClientId } -> EditEvent -> Command BackendOnly Types.ToFrontend BackendMsg
cmdOfEditor editor event =
    Effect.Lamdera.sendToFrontend editor.clientId (ProcessEvent event)
