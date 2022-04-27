module Network exposing
    ( EditEvent
    , NetworkModel
    , ServerState
    , applyEvent
    , createEvent
    , emptyServerState
    , getLocalDocument
    , init
    , updateFromUser
    )

import Dict exposing (Dict)
import Document
import List.Extra
import OT


type alias UserId =
    String



--type Event
--    = MovedCursor UserId { xOffset : Int, yOffset : Int } -- Offset relative to the previous cursor position
--    | TypedText UserId String


type alias EditEvent =
    { userId : String, dp : Int, dx : Int, dy : Int, operations : List OT.Operation }


type alias ServerState =
    { cursorPositions : Dict UserId { x : Int, y : Int, p : Int }
    , document : OT.Document
    }


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
            OT.findOps oldDocument newDocument |> Debug.log "!! OT Ops"
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
updateFromBackend updateFunc msg localModel =
    { localMsgs = List.Extra.remove msg localModel.localMsgs
    , serverState = updateFunc msg localModel.serverState
    }
