module CollaborativeEditing.NetworkSimulator2 exposing (..)

import CollaborativeEditing.NetworkModel as NetworkModel exposing (EditEvent, NetworkModel)
import CollaborativeEditing.OT as OT exposing (Operation(..))
import CollaborativeEditing.OTCommand as OTCommand exposing (Command)
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


nextStep : State -> Step State State
nextStep state =
    case List.head state.input of
        Nothing ->
            Done state

        Just editorAction ->
            let
                _ =
                    Debug.log "ACTION" editorAction
            in
            Loop (updateState editorAction state)


updateState : EditorAction -> State -> State
updateState action state =
    state
        |> performEdit action
        |> updateFromBackend
        |> (\state_ -> { state_ | input = List.drop 1 state.input })


run : String -> List EditorAction -> State
run content actions =
    let
        state_ =
            initialState content

        state =
            { state_ | input = actions }
    in
    loop state nextStep


loop : state -> (state -> Step state a) -> a
loop s f =
    case f s of
        Loop s_ ->
            loop s_ f

        Done b ->
            b


type alias UserState =
    { user : SUser, editor : OT.Document, model : NetworkModel }


type SUser
    = UserA
    | UserB


type alias Cursor =
    Int


type EditOp
    = EInsert Cursor String
    | EDelete Cursor Int
    | EMoveCursor Cursor
    | ENoOp


type alias EditorAction =
    { user : SUser, op : EditOp }


type Step a b
    = Loop a
    | Done b


toEditOps : Cursor -> EditEvent -> List EditOp
toEditOps cursor event =
    case toEditOpAux cursor ( event, [] ) of
        Loop _ ->
            []

        Done ops ->
            ops


toEditOpAux : Cursor -> ( EditEvent, List EditOp ) -> Step ( EditEvent, List EditOp ) (List EditOp)
toEditOpAux cursor ( event, ops ) =
    case List.head event.operations of
        Nothing ->
            Done ops

        Just op ->
            case op of
                Insert cur str ->
                    Loop ( { event | operations = List.drop 1 event.operations }, EInsert cur str :: ops )

                Delete cur n ->
                    Loop ( { event | operations = List.drop 1 event.operations }, EDelete cur n :: ops )

                MoveCursor _ ->
                    Loop ( { event | operations = List.drop 1 event.operations }, ops )


applyEditOp : EditOp -> OT.Document -> OT.Document
applyEditOp op doc =
    case op of
        EInsert cursor str ->
            { doc | cursor = cursor + String.length str, content = String.Extra.insertAt str cursor doc.content }

        EDelete cursor n ->
            { doc | cursor = cursor, content = deleteAt cursor n doc.content }

        EMoveCursor cursor ->
            { doc | cursor = cursor }

        ENoOp ->
            doc



-- PERFORM EDIT


performEdit : EditorAction -> State -> State
performEdit action state =
    case action.user of
        UserA ->
            let
                ( userState, event ) =
                    performEditOnUserState "A" action state.a
            in
            { state | a = userState, server = Deque.pushFront event state.server }

        UserB ->
            let
                ( userState, event ) =
                    performEditOnUserState "B" action state.a
            in
            { state | b = userState, server = Deque.pushFront event state.server }


performEditOnUserState : String -> EditorAction -> UserState -> ( UserState, EditEvent )
performEditOnUserState userId action state =
    let
        editor =
            applyEditOp (Debug.log "OP" action.op) state.editor |> Debug.log "editor after OP"

        event =
            NetworkModel.createEvent userId (Debug.log "OLD" state.editor) (Debug.log "NEW" editor)

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


updateFromBackend : State -> State
updateFromBackend state =
    case Deque.last state.server of
        Nothing ->
            state

        Just event ->
            let
                modelA =
                    state.a.model |> Debug.log "modelA"

                newNetworkModelA =
                    NetworkModel.updateFromBackend NetworkModel.applyEvent2 event state.a.model
                        |> Debug.log "newNetworkModelA"

                cursorA =
                    modelA.serverState.document.cursor

                editOpsA =
                    toEditOps cursorA event

                modelB =
                    state.b.model

                newNetworkModelB =
                    NetworkModel.updateFromBackend NetworkModel.applyEvent2 event state.b.model

                cursorB =
                    modelB.serverState.document.cursor

                editOpsB =
                    toEditOps cursorB event

                ( _, deque ) =
                    Deque.popBack state.server
            in
            { a = { user = state.a.user, editor = newNetworkModelA.serverState.document, model = newNetworkModelA }
            , b = { user = state.b.user, editor = newNetworkModelB.serverState.document, model = newNetworkModelB }
            , server = deque
            , input = List.drop 1 state.input
            , count = state.count + 1
            }



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
    { user = UserA, op = EMoveCursor 2 }


state1 =
    performEdit editAction1 state0


state1b =
    updateFromBackend state1


editAction2 =
    { user = UserA, op = EInsert 2 "X" }


state2 =
    performEdit editAction2 state1b


state2b =
    updateFromBackend state2


editAction3 =
    { user = UserA, op = EInsert 5 "Y" }


state3 =
    performEdit editAction3 state2b


state3b =
    updateFromBackend state3
