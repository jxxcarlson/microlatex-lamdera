module Backend.NetworkModel exposing (processEvent)

import Dict
import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import NetworkModel exposing (EditEvent)
import Types exposing (AbstractDict, BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentDict, DocumentHandling(..), MessageStatus(..), ToFrontend(..), UsersDocumentsDict)


processEventList : BackendModel -> ( BackendModel, Cmd BackendMsg )
processEventList model =
    let
        events =
            List.take 5 model.editEvents

        cmds =
            List.map (processEventCmd model.sharedDocumentDict) events
    in
    ( { model | editEvents = List.drop 5 model.editEvents }, Cmd.batch cmds )


processEvent : BackendModel -> ( BackendModel, Cmd BackendMsg )
processEvent model =
    case List.head model.editEvents of
        Nothing ->
            ( model, Cmd.none )

        Just event ->
            ( { model | editEvents = List.drop 1 model.editEvents }, processEventCmd model.sharedDocumentDict event )


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
