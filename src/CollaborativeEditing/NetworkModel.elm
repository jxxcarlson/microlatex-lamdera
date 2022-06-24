module CollaborativeEditing.NetworkModel exposing
    ( EditEvent
    , NetworkModel
    , ServerState
    , applyEvent
    , applyLocalEvents
    , createEvent
    , getLocalDocument
    , init
    , initWithUsersAndContent
    , initialServerState
    , nullEvent
    , shortenDictKeys
    , toString1
    , toStringList
    , updateFromBackend
    , updateFromUser
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
    { docId : String, userId : String, dp : Int, operations : List OT.Operation }



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


updateFromUser : EditEvent -> NetworkModel -> NetworkModel
updateFromUser event localModel =
    { localMsgs = localModel.localMsgs ++ [ event ]
    , serverState = localModel.serverState
    }


updateFromBackend : (EditEvent -> ServerState -> ServerState) -> EditEvent -> NetworkModel -> NetworkModel
updateFromBackend updateFunc event localModel =
    { localMsgs = List.Extra.remove event localModel.localMsgs
    , serverState = updateFunc event localModel.serverState
    }



-- LOCAL


localState : (EditEvent -> ServerState -> ServerState) -> NetworkModel -> ServerState
localState updateFunc localModel =
    List.foldl updateFunc localModel.serverState localModel.localMsgs


getLocalDocument : NetworkModel -> OT.Document
getLocalDocument localModel =
    localState applyEvent localModel |> .document



-- ENCODE


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



-- CREATE AND APPLY EVENTS


createEvent : String -> OT.Document -> OT.Document -> EditEvent
createEvent userId_ oldDocument newDocument =
    let
        dp =
            newDocument.cursor - oldDocument.cursor

        operations : List OT.Operation
        operations =
            OT.findOps oldDocument newDocument
    in
    { docId = oldDocument.docId, userId = userId_, dp = dp, operations = operations }


applyLocalEvents : (EditEvent -> ServerState -> ServerState) -> NetworkModel -> NetworkModel
applyLocalEvents updateFunc localModel =
    let
        newServerState =
            List.foldl (\event serverState -> updateFunc event serverState) localModel.serverState localModel.localMsgs
    in
    { localMsgs = [], serverState = newServerState }


applyEvent : EditEvent -> ServerState -> ServerState
applyEvent event serverState =
    case Dict.get event.userId serverState.cursorPositions of
        Nothing ->
            --serverState
            -- TODO: changed from 'serverState' to the below temporarily
            -- TODO: so that events from different user will be applied.
            -- TODO: Need to understand the process: why the Dict.get ...
            { cursorPositions = serverState.cursorPositions
            , document = OT.apply event.operations serverState.document
            }

        Just p ->
            { cursorPositions = Dict.insert event.userId (p + event.dp) serverState.cursorPositions
            , document = OT.apply event.operations serverState.document
            }



-- TO STRING


toStringList : EditEvent -> { ids : String, dp : String, ops : String }
toStringList event =
    let
        ids =
            "(" ++ (event.userId |> String.left 2) ++ ", " ++ (event.docId |> String.dropLeft 3 |> String.left 2) ++ ")"

        dp =
            String.fromInt event.dp

        ops =
            List.map OT.toString event.operations |> String.join "; "
    in
    { ids = ids, dp = dp, ops = ops }


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
