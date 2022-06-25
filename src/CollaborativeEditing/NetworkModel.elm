module CollaborativeEditing.NetworkModel exposing
    ( EditEvent
    , NetworkModel
    , ServerState
    , appendEvent
    , applyLocalEvents
    , createEvent
    , getLocalDocument
    , init
    , initWithUsersAndContent
    , initialServerState
    , nullEvent
    , shortenDictKeys
    , toString1
    , toStringRecord
    , updateFromBackend
    )

import CollaborativeEditing.OT as OT
import Dict exposing (Dict)
import Json.Encode as E
import List.Extra


type alias NetworkModel =
    { localMsgs : List EditEvent, serverState : ServerState }


type alias ServerState =
    { cursorPositions : Dict UserId Int
    , document : OT.Document
    }


type alias UserId =
    String


type alias DocId =
    String


type alias EditEvent =
    { docId : String, userId : String, dp : Int, operation : OT.Operation }



-- INIT


init : ServerState -> NetworkModel
init serverState =
    { localMsgs = [], serverState = serverState }


initWithUsersAndContent : DocId -> List UserId -> String -> NetworkModel
initWithUsersAndContent docId userIds content =
    init (manyUserInitialServerState docId userIds content)


initialServerState : DocId -> UserId -> String -> ServerState
initialServerState docId userId content =
    { cursorPositions = Dict.fromList [ ( userId, 0 ) ]
    , document = { docId = docId, cursor = 0, content = content }
    }


manyUserInitialServerState : DocId -> List UserId -> String -> ServerState
manyUserInitialServerState docId userIds content =
    { cursorPositions = Dict.fromList (List.map (\id -> ( id, 0 )) userIds)
    , document = { docId = docId, cursor = 0, content = content }
    }



-- UPDATE


appendEvent : EditEvent -> NetworkModel -> NetworkModel
appendEvent event localModel =
    { localMsgs = localModel.localMsgs ++ [ event ]
    , serverState = localModel.serverState
    }


updateFromBackend : EditEvent -> NetworkModel -> NetworkModel
updateFromBackend event localModel =
    { localMsgs = List.Extra.remove event localModel.localMsgs
    , serverState = applyEventToServerState event localModel.serverState
    }



-- LOCAL


localState : NetworkModel -> ServerState
localState localModel =
    List.foldl applyEventToServerState localModel.serverState localModel.localMsgs


getLocalDocument : NetworkModel -> OT.Document
getLocalDocument localModel =
    localState localModel |> .document



-- ENCODE


encodeEvent : { counter : Int, cursor : Int, event : EditEvent } -> E.Value
encodeEvent { counter, cursor, event } =
    E.object
        [ ( "name", E.string "OTOp" )
        , ( "dp", E.int event.dp )
        , ( "op", OT.encodeOperation event.operation )
        , ( "cursor", E.int cursor )
        , ( "counter", E.int counter )
        ]


nullEvent : E.Value
nullEvent =
    E.object [ ( "name", E.string "OTNull" ) ]



-- CREATE AND APPLY EVENTS


createEvent : String -> OT.Document -> OT.Document -> EditEvent
createEvent userId_ oldDocument newDocument =
    { docId = oldDocument.docId
    , userId = userId_
    , dp = newDocument.cursor - oldDocument.cursor
    , operation = OT.findOp oldDocument newDocument
    }


applyLocalEvents : NetworkModel -> NetworkModel
applyLocalEvents localModel =
    let
        newServerState =
            List.foldl applyEventToServerState localModel.serverState localModel.localMsgs
    in
    { localMsgs = [], serverState = newServerState }


applyEventToServerState : EditEvent -> ServerState -> ServerState
applyEventToServerState event serverState =
    case Dict.get event.userId serverState.cursorPositions of
        Nothing ->
            --serverState
            -- TODO: changed from 'serverState' to the below temporarily
            -- TODO: so that events from different user will be applied.
            -- TODO: Need to understand the process: why the Dict.get ...
            { cursorPositions = serverState.cursorPositions
            , document = OT.applyOp event.operation serverState.document
            }

        Just p ->
            { cursorPositions = Dict.insert event.userId (p + event.dp) serverState.cursorPositions
            , document = OT.applyOp event.operation serverState.document
            }



-- TO STRING


toStringRecord : EditEvent -> { ids : String, dp : String, op : String }
toStringRecord event =
    let
        ids =
            "(" ++ (event.userId |> String.left 2) ++ ", " ++ (event.docId |> String.dropLeft 3 |> String.left 2) ++ ")"
    in
    { ids = ids, dp = String.fromInt event.dp, op = OT.toString event.operation }


shortenDictKeys : Dict String a -> Dict String a
shortenDictKeys dict =
    dict
        |> Dict.toList
        |> List.map (\( k, v ) -> ( String.right 3 k, v ))
        |> Dict.fromList


toString1 : { counter : Int, cursor : Int, event : Maybe EditEvent } -> String
toString1 { counter, cursor, event } =
    case event of
        Nothing ->
            "null: " ++ String.fromInt counter

        Just event_ ->
            { counter = counter, cursor = cursor, event = event_ } |> encodeEvent |> E.encode 2
