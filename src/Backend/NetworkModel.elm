module Backend.NetworkModel exposing (processEvent)

import Deque
import Dict
import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import NetworkModel exposing (EditEvent)
import Types exposing (AbstractDict, BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentDict, DocumentHandling(..), MessageStatus(..), ToFrontend(..), UsersDocumentsDict)


processEvent : BackendModel -> ( BackendModel, Cmd BackendMsg )
processEvent model =
    let
        ( mEvent, deque ) =
            Deque.popBack model.editEvents

        cmd =
            case mEvent of
                Nothing ->
                    Cmd.none

                Just evt ->
                    processEventCmd model.sharedDocumentDict evt
    in
    ( { model | editEvents = deque }, cmd )


processEventCmd : Types.SharedDocumentDict -> EditEvent -> Cmd BackendMsg
processEventCmd sharedDocumentDict event =
    case Dict.get event.docId sharedDocumentDict of
        Nothing ->
            Cmd.none |> Debug.log "PROCESS, Nothing"

        Just sharedDoc ->
            let
                _ =
                    Debug.log "PROCESS, currentEditors" sharedDoc.currentEditors
            in
            Cmd.batch (List.foldl (\editor cmds -> cmdOfEditor editor event :: cmds) [] sharedDoc.currentEditors)


cmdOfEditor : { a | clientId : ClientId } -> EditEvent -> Cmd BackendMsg
cmdOfEditor editor event =
    sendToFrontend editor.clientId (ProcessEvent event)
