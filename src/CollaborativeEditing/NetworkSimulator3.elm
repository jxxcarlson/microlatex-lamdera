module CollaborativeEditing.NetworkSimulator3 exposing (State, applyEditOperation, applyEventAtServer, applyEventToLocalState, applyEventToState, init, initialState, m1, nextStep, run, sendToServer, update, user1, user2)

import CollaborativeEditing.NetworkModel2 as NetworkModel
    exposing
        ( LocalState
        , Server
        , UserData
        , initialServer
        , setLocalState
        , startSession
        )
import CollaborativeEditing.OT as OT
import CollaborativeEditing.Types
    exposing
        ( DocId
        , EditEvent
        , Msg(..)
        , Username
        )
import Dict exposing (Dict)
import Util exposing (Step(..), loop)


type alias State =
    { localStates : Dict Username LocalState, server : Server, count : Int }


run : ( State, Msg ) -> State
run ( state, msg ) =
    loop ( state, msg ) nextStep


nextStep : ( State, Msg ) -> Step ( State, Msg ) State
nextStep ( state, msg ) =
    case msg of
        CENoOp ->
            Done state

        _ ->
            Loop (update msg state)


update : Msg -> State -> ( State, Msg )
update msg state =
    let
        _ =
            Debug.log "step" ( state.count, msg )
    in
    case msg of
        Edit ( username, op ) ->
            -- 1. message = ApplyEventToLocalState
            applyEditOperation ( username, op ) { state | count = state.count + 1 }

        ApplyEventToLocalState username docId editEvent ->
            -- 2. message = SendToServer
            applyEventToLocalState username docId editEvent { state | count = state.count + 1 }

        SendToServer username docId editEvent ->
            -- 3. message =
            sendToServer username editEvent { state | count = state.count + 1 }

        ProcessEventAtServer username docId editEvent ->
            ( applyEventToState username docId editEvent { state | count = state.count + 1 }, CENoOp )

        CENoOp ->
            ( { state | count = state.count + 1 }, CENoOp )


applyEventAtServer : Username -> DocId -> EditEvent -> Server -> Server
applyEventAtServer username docId editEvent server =
    case Dict.get docId server.documents of
        Nothing ->
            server

        Just doc ->
            let
                newDoc =
                    NetworkModel.applyEvent editEvent doc

                documents =
                    Dict.insert docId newDoc server.documents
            in
            { server | documents = documents }


applyEventToState : Username -> DocId -> EditEvent -> State -> State
applyEventToState username docId editEvent state =
    { state | server = applyEventAtServer username docId editEvent state.server }


sendToServer : Username -> EditEvent -> State -> ( State, Msg )
sendToServer username editEvent state =
    case Dict.get username state.localStates of
        Nothing ->
            ( state, CENoOp )

        Just localState_ ->
            let
                ( ls, msg ) =
                    NetworkModel.sendChanges localState_
            in
            ( { state | localStates = Dict.insert username ls state.localStates }, msg )



-- sendChanges localState


applyEventToLocalState : Username -> DocId -> EditEvent -> State -> ( State, Msg )
applyEventToLocalState username docId editEvent state =
    case Dict.get username state.localStates of
        Nothing ->
            ( state, CENoOp )

        Just localState_ ->
            let
                ( localState, _ ) =
                    NetworkModel.applyEventToLocalState ( localState_, editEvent )
            in
            ( { state | localStates = Dict.insert username localState state.localStates }, SendToServer username docId editEvent )


applyEditOperation : ( Username, OT.Operation ) -> State -> ( State, Msg )
applyEditOperation ( username, op ) state =
    case Dict.get username state.localStates of
        Nothing ->
            ( state, CENoOp )

        Just localState_ ->
            let
                ( localState, editEvent ) =
                    NetworkModel.applyEditorOperations [ op ] localState_

                docId =
                    localState.localModel.localDocument.docId
            in
            ( { state | localStates = Dict.insert username localState state.localStates }, ApplyEventToLocalState username docId editEvent )


init : DocId -> List UserData -> String -> State
init docId users content =
    { localStates = Dict.fromList (List.map2 (\a b -> ( a, b )) (List.map .username users) (List.map (setLocalState docId content) users))
    , server = startSession docId users content initialServer
    , count = 0
    }


user1 =
    { username = "Alice", clientId = "A" }


user2 =
    { username = "Bob", clientId = "B" }


initialState =
    init "doc" [ user1, user2 ] ""


m1 =
    Edit ( "Alice", OT.Insert 0 "abc" )
