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
    , manyUserInitialServerState
    , nullEvent
    , toString
    , updateFromBackend
    , updateFromUser
    )

import Dict exposing (Dict)
import Json.Encode as E
import List.Extra
import OT


type alias UserId =
    String


type alias DocId =
    String


type alias EditEvent =
    { docId : String, userId : String, dp : Int, dx : Int, dy : Int, operations : List OT.Operation }


type alias ServerState =
    { cursorPositions : Dict UserId { x : Int, y : Int, p : Int }
    , document : OT.Document
    }


toString : { counter : Int, cursor : Int, event : Maybe EditEvent } -> String
toString { counter, cursor, event } =
    case event of
        Nothing ->
            "null: " ++ String.fromInt counter

        Just event_ ->
            { counter = counter, cursor = cursor, event = event_ } |> encodeEvent |> E.encode 2


encodeEvent : { counter : Int, cursor : Int, event : EditEvent } -> E.Value
encodeEvent { counter, cursor, event } =
    E.object
        [ ( "name", E.string "OTOp" )
        , ( "dp", E.int event.dp )
        , ( "dx", E.int event.dx )
        , ( "dy", E.int event.dy )
        , ( "ops", E.list OT.encodeOperation event.operations )
        , ( "cursor", E.int cursor )
        , ( "counter", E.int counter )
        ]


nullEvent : E.Value
nullEvent =
    E.object [ ( "name", E.string "OTNull" ) ]


initialServerState : DocId -> UserId -> String -> ServerState
initialServerState docId userId content =
    { cursorPositions = Dict.fromList [ ( userId, { x = 0, y = 0, p = 0 } ) ]
    , document = { id = docId, cursor = 0, x = 0, y = 0, content = content }
    }


manyUserInitialServerState : DocId -> List UserId -> String -> ServerState
manyUserInitialServerState docId userIds content =
    { cursorPositions = Dict.fromList (List.map (\id -> ( id, { x = 0, y = 0, p = 0 } )) userIds)
    , document = { id = docId, cursor = 0, x = 0, y = 0, content = content }
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
            OT.findOps oldDocument newDocument
    in
    { docId = oldDocument.id, userId = userId_, dx = dx, dy = dy, dp = dp, operations = operations }


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


initWithUserAndContent : DocId -> UserId -> String -> NetworkModel
initWithUserAndContent docId userId content =
    init (initialServerState docId userId content)


initWithUsersAndContent : DocId -> List UserId -> String -> NetworkModel
initWithUsersAndContent docId userIds content =
    init (manyUserInitialServerState docId userIds content)


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
