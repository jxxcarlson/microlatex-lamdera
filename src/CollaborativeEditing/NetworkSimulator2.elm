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
    , server : Server
    , input : List EditorAction
    , count : Int
    }


type alias Server =
    { events : Deque EditEvent, document : OT.Document }


type alias UserState =
    { user : SUser, editor : OT.Document, model : NetworkModel }


type SUser
    = UserA
    | UserB


type alias Cursor =
    Int


type alias EditorAction =
    { user : SUser, op : OT.Operation }


type Step a b
    = Loop a
    | Done b


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


toOps : Cursor -> ( EditEvent, List OT.Operation ) -> Step ( EditEvent, List OT.Operation ) (List OT.Operation)
toOps cursor ( event, ops ) =
    case List.head event.operations of
        Nothing ->
            Done ops

        Just op ->
            case op of
                Insert cur str ->
                    Loop ( { event | operations = List.drop 1 event.operations }, Insert cur str :: ops )

                Delete cur n ->
                    Loop ( { event | operations = List.drop 1 event.operations }, Delete cur n :: ops )

                MoveCursor _ ->
                    Loop ( { event | operations = List.drop 1 event.operations }, ops )

                OTNoOp ->
                    Loop ( { event | operations = List.drop 1 event.operations }, ops )


applyEditOp : OT.Operation -> OT.Document -> OT.Document
applyEditOp op doc =
    case op of
        Insert cursor str ->
            { doc | cursor = cursor + String.length str, content = String.Extra.insertAt str cursor doc.content }

        Delete cursor n ->
            let
                _ =
                    Debug.log "Delete" ( cursor, n )
            in
            { doc | cursor = cursor, content = deleteAt n (cursor - 1) doc.content |> Debug.log "DELETE" }

        MoveCursor cursor ->
            { doc | cursor = cursor }

        OTNoOp ->
            doc



-- PERFORM EDIT


{-| perform edit on document, update local state, and send message to the server
-}
performEdit : EditorAction -> State -> State
performEdit action state =
    case action.user of
        UserA ->
            let
                ( userState, event ) =
                    performEditOnUserState "A" action state.a
            in
            { state
                | a = userState
                , server = sendEventToServer event state.server
            }

        UserB ->
            let
                ( userState, event ) =
                    performEditOnUserState "B" action state.a
            in
            { state
                | b = userState
                , server = sendEventToServer event state.server
            }


sendEventToServer : EditEvent -> Server -> Server
sendEventToServer event server =
    { server | events = Deque.pushFront event server.events }


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
    case Deque.last state.server.events of
        Nothing ->
            state

        Just event ->
            let
                modelA =
                    state.a.model |> Debug.log "modelA"

                newNetworkModelA =
                    let
                        _ =
                            Debug.log "Network Model" "A"
                    in
                    NetworkModel.updateFromBackend NetworkModel.applyEvent2 event state.a.model
                        |> Debug.log "newNetworkModelA"

                cursorA =
                    modelA.serverState.document.cursor

                --editOpsA =
                --    toOps cursorA event
                modelB =
                    state.b.model

                newNetworkModelB =
                    let
                        _ =
                            Debug.log "Network Model" "B"
                    in
                    NetworkModel.updateFromBackend NetworkModel.applyEvent2 event state.b.model

                cursorB =
                    modelB.serverState.document.cursor

                --editOpsB =
                --    toOps cursorB event
                ( _, deque ) =
                    Deque.popBack state.server.events

                oldServer =
                    state.server
            in
            { a = { user = state.a.user, editor = newNetworkModelA.serverState.document, model = newNetworkModelA }
            , b = { user = state.b.user, editor = newNetworkModelB.serverState.document, model = newNetworkModelB }
            , server = { oldServer | events = deque }
            , input = List.drop 1 state.input
            , count = state.count + 1
            }



-- INITIALIZERS


initialState : String -> State
initialState source =
    { a = { user = UserA, editor = { docId = "doc", cursor = 0, content = source }, model = initialNetworkModel source }
    , b = { user = UserB, editor = { docId = "doc", cursor = 0, content = source }, model = initialNetworkModel source }
    , server = { events = Deque.empty, document = { docId = "doc", cursor = 0, content = source } }
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
    { user = UserA, op = MoveCursor 2 }


state1 =
    performEdit editAction1 state0


state1b =
    updateFromBackend state1


editAction2 =
    { user = UserA, op = Insert 2 "X" }


state2 =
    performEdit editAction2 state1b


state2b =
    updateFromBackend state2


editAction3 =
    { user = UserA, op = Insert 5 "Y" }


state3 =
    performEdit editAction3 state2b


state3b =
    updateFromBackend state3
