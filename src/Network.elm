module Network exposing (..)

import Dict exposing (Dict)
import List.Extra


type alias UserId =
    String



--type Event
--    = MovedCursor UserId { xOffset : Int, yOffset : Int } -- Offset relative to the previous cursor position
--    | TypedText UserId String


type alias EditEvent =
    { userId : String, dx : Int, dy : Int, content : String }


type alias ServerState =
    { cursorPositions : Dict UserId { x : Int, y : Int }
    , content : String
    }


f : EditEvent -> ServerState -> ServerState
f event serverState =
    case Dict.get event.userId serverState.cursorPositions of
        Nothing ->
            serverState

        Just { x, y } ->
            { cursorPositions = Dict.insert event.userId { x = x + event.dx, y = y + event.dy } serverState.cursorPositions
            , content = event.content
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


updateFromBackend : (EditEvent -> ServerState -> ServerState) -> EditEvent -> NetworkModel -> NetworkModel
updateFromBackend updateFunc msg localModel =
    { localMsgs = List.Extra.remove msg localModel.localMsgs
    , serverState = updateFunc msg localModel.serverState
    }
