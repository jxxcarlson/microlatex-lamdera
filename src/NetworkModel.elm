module NetworkModel exposing
    ( EditEvent
    , NetworkModel
    , ServerState
    , applyEvent
    , createEvent
    , emptyServerState
    , getLocalDocument
    , init
    , initWithUserAndContent
    , initWithUsersAndContent
    , initialServerState
    , initialServerState2
    , updateFromBackend
    , updateFromUser
    )

import Dict exposing (Dict)
import Document
import List.Extra
import OT


type alias UserId =
    String


type alias EditEvent =
    { userId : String, dp : Int, dx : Int, dy : Int, operations : List OT.Operation }


type alias ServerState =
    { cursorPositions : Dict UserId { x : Int, y : Int, p : Int }
    , document : OT.Document
    }


initialServerState : UserId -> String -> ServerState
initialServerState userId content =
    { cursorPositions = Dict.fromList [ ( userId, { x = 0, y = 0, p = 0 } ) ], document = { cursor = 0, x = 0, y = 0, content = content } }


initialServerState2 : List UserId -> String -> ServerState
initialServerState2 userIds content =
    { cursorPositions = Dict.fromList (List.map (\id -> ( id, { x = 0, y = 0, p = 0 } )) userIds), document = { cursor = 0, x = 0, y = 0, content = content } }


emptyServerState =
    { cursorPositions = Dict.empty
    , document = OT.emptyDoc
    }


createEvent : String -> OT.Document -> OT.Document -> EditEvent
createEvent userId_ oldDocument newDocument =
    let
        dp =
            newDocument.cursor - oldDocument.cursor

        dx =
            newDocument.x - oldDocument.x

        dy =
            newDocument.y - oldDocument.y

        operations : List OT.Operation
        operations =
            OT.findOps oldDocument newDocument
    in
    { userId = userId_, dx = dx, dy = dy, dp = dp, operations = operations }


applyEvent : EditEvent -> ServerState -> ServerState
applyEvent event serverState =
    case Dict.get event.userId serverState.cursorPositions of
        Nothing ->
            serverState

        Just { x, y, p } ->
            { cursorPositions = Dict.insert event.userId { x = x + event.dx, y = y + event.dy, p = p + event.dp } serverState.cursorPositions
            , document = OT.apply event.operations serverState.document
            }


type alias NetworkModel =
    { localMsgs : List EditEvent, serverState : ServerState }


init : ServerState -> NetworkModel
init serverState =
    { localMsgs = [], serverState = serverState }


initWithUserAndContent : UserId -> String -> NetworkModel
initWithUserAndContent userId content =
    init (initialServerState userId content)


initWithUsersAndContent : List UserId -> String -> NetworkModel
initWithUsersAndContent userIds content =
    init (initialServerState2 userIds content)


updateFromUser : EditEvent -> NetworkModel -> NetworkModel
updateFromUser event localModel =
    { localMsgs = localModel.localMsgs ++ [ event ]
    , serverState = localModel.serverState
    }


localState : (EditEvent -> ServerState -> ServerState) -> NetworkModel -> ServerState
localState updateFunc localModel =
    List.foldl updateFunc localModel.serverState localModel.localMsgs


getLocalDocument : NetworkModel -> OT.Document
getLocalDocument localModel =
    localState applyEvent localModel |> .document


updateFromBackend : (EditEvent -> ServerState -> ServerState) -> EditEvent -> NetworkModel -> NetworkModel
updateFromBackend updateFunc event localModel =
    { localMsgs = List.Extra.remove event localModel.localMsgs
    , serverState = updateFunc event localModel.serverState
    }
