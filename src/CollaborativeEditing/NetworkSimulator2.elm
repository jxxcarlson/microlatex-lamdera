module CollaborativeEditing.NetworkSimulator2 exposing (..)

import CollaborativeEditing.NetworkModel as NetworkModel exposing (EditEvent, NetworkModel)
import CollaborativeEditing.OT as OT exposing (Operation(..))
import Deque exposing (Deque)
import Dict
import String.Extra
import Util exposing (Step(..), loop)



-- TYPES


type alias State =
    { a : UserState
    , b : UserState
    , server : Deque EditEvent
    , input : List EditorAction
    , count : Int
    }


type alias UserState =
    { user : SimUser, editor : OT.Document, model : NetworkModel }


type SimUser
    = UserA
    | UserB


type alias Cursor =
    Int


type EditOp
    = SInsert Cursor String
    | SDelete Cursor Int
    | SMoveCursor Cursor


type alias EditorAction =
    { user : SimUser, op : EditOp }


applyEditOp : EditOp -> OT.Document -> OT.Document
applyEditOp op doc =
    case op of
        SInsert cursor str ->
            { doc | cursor = cursor, content = String.Extra.insertAt str cursor doc.content }

        SDelete cursor n ->
            { doc | cursor = cursor, content = deleteAt cursor n doc.content }

        SMoveCursor cursor ->
            { doc | cursor = cursor }



-- PERFORM EDIT


performEdit : EditorAction -> State -> State
performEdit action state =
    case action.user of
        UserA ->
            let
                ( userState, event ) =
                    performEditOnUserState "a" action state.a
            in
            { state | a = userState, server = Deque.pushFront event state.server }

        UserB ->
            let
                ( userState, event ) =
                    performEditOnUserState "a" action state.a
            in
            { state | b = userState, server = Deque.pushFront event state.server }


performEditOnUserState : String -> EditorAction -> UserState -> ( UserState, EditEvent )
performEditOnUserState userId action state =
    let
        editor =
            applyEditOp action.op state.editor

        event =
            NetworkModel.createEvent userId state.editor editor

        oldServerState =
            state.model.serverState

        oldCursorPositions =
            state.model.serverState.cursorPositions

        serverState =
            { oldServerState
                | cursorPositions = Dict.insert userId editor.cursor oldCursorPositions
                , document = editor
            }
    in
    ( { state | editor = editor, model = { localMsgs = [ event ], serverState = serverState } }
    , event
    )



-- UPDATE
-- INITIALIZERS


initialState source =
    { a = { user = UserA, editor = { id = "doc", cursor = 0, content = source }, model = initialNetworkModel source }
    , b = { user = UserB, editor = { id = "doc", cursor = 0, content = source }, model = initialNetworkModel source }
    , server = Deque.empty
    , input = []
    , count = 0
    }


initialDocument source =
    { content = source
    , cursor = 0
    , id = "111"
    }


initialNetworkModel source =
    { localMsgs = []
    , serverState =
        { cursorPositions =
            Dict.fromList
                [ ( "A", 0 )
                , ( "B", 0 )
                ]
        , document = initialDocument source
        }
    }



--HELPERS


deleteAt i n str =
    String.left (n + 1) str ++ String.dropLeft (i + n + 1) str



-- SIMULATION BY HAND


state0 : State
state0 =
    initialState "abcd"


editAction1 =
    { user = UserA, op = SMoveCursor 3 }


state1 =
    performEdit editAction1 state0
