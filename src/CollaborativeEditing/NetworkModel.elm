module CollaborativeEditing.NetworkModel exposing
    ( EditEvent
    , NetworkModel
    , ServerState
    , applyEvent
    , applyEvent2
    , createEvent
    , emptyServerState
    , getLocalDocument
    , init
    , initWithUserAndContent
    , initWithUsersAndContent
    , initialServerState
    , manyUserInitialServerState
    , nullEvent
    , shortenDictKeys
    , toString
    , updateFromBackend
    , updateFromUser
    )

import CollaborativeEditing.OT as OT
import Dict exposing (Dict)
import Json.Encode as E
import List.Extra


type alias UserId =
    String


type alias DocId =
    String


type alias EditEvent =
    { docId : String, userId : String, dp : Int, operations : List OT.Operation }


type alias NetworkModel =
    { localMsgs : List EditEvent, serverState : ServerState }


type alias ServerState =
    { cursorPositions : Dict UserId Int
    , document : OT.Document
    }


shortenDictKeys : Dict String a -> Dict String a
shortenDictKeys dict =
    dict
        |> Dict.toList
        |> List.map (\( k, v ) -> ( String.right 3 k, v ))
        |> Dict.fromList


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
        , ( "ops", E.list OT.encodeOperation event.operations )
        , ( "cursor", E.int cursor )
        , ( "counter", E.int counter )
        ]


nullEvent : E.Value
nullEvent =
    E.object [ ( "name", E.string "OTNull" ) ]


initialServerState : DocId -> UserId -> String -> ServerState
initialServerState docId userId content =
    { cursorPositions = Dict.fromList [ ( userId, 0 ) ]
    , document = { id = docId, cursor = 0, content = content }
    }


manyUserInitialServerState : DocId -> List UserId -> String -> ServerState
manyUserInitialServerState docId userIds content =
    { cursorPositions = Dict.fromList (List.map (\id -> ( id, 0 )) userIds)
    , document = { id = docId, cursor = 0, content = content }
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

        _ =
            Debug.log "!! (old, new, dp)" ( oldDocument.cursor, newDocument.cursor, dp )

        operations : List OT.Operation
        operations =
            OT.findOps oldDocument newDocument
    in
    { docId = oldDocument.id, userId = userId_, dp = dp, operations = operations } |> Debug.log "!! CREATE EVENT"


applyEvent : EditEvent -> ServerState -> ServerState
applyEvent event serverState =
    case Dict.get event.userId serverState.cursorPositions of
        Nothing ->
            serverState

        Just p ->
            { cursorPositions = Dict.insert event.userId (p + event.dp) serverState.cursorPositions
            , document = OT.apply event.operations serverState.document
            }


applyEvent2 : EditEvent -> ServerState -> ServerState
applyEvent2 event serverState =
    case Dict.get event.userId serverState.cursorPositions of
        Nothing ->
            serverState

        Just p ->
            { cursorPositions = Dict.insert event.userId (p + event.dp) serverState.cursorPositions
            , document = OT.apply event.operations serverState.document
            }


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
