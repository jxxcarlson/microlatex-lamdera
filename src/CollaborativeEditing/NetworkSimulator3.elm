module CollaborativeEditing.NetworkSimulator3 exposing (..)

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


update : Msg -> State -> ( State, Msg )
update msg state =
    case msg of
        Edit ( username, op ) ->
            -- 1. message = ApplyEventToLocalState
            applyEditOperation ( username, op ) state

        ApplyEventToLocalState username editEvent ->
            -- 2. message = SendToServer
            applyEventToLocalState username editEvent state

        SendToServer username editEvent ->
            -- 3. message =
            sendToServer username editEvent state

        ProcessEvent username editEvent ->



type alias State =
    { localStates : Dict Username LocalState, server : Server }


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


applyEventToLocalState : Username -> EditEvent -> State -> ( State, Msg )
applyEventToLocalState username editEvent state =
    case Dict.get username state.localStates of
        Nothing ->
            ( state, CENoOp )

        Just localState_ ->
            let
                ( localState, _ ) =
                    NetworkModel.applyEventToLocalState ( localState_, editEvent )
            in
            ( { state | localStates = Dict.insert username localState state.localStates }, SendToServer username editEvent )


applyEditOperation : ( Username, OT.Operation ) -> State -> ( State, Msg )
applyEditOperation ( username, op ) state =
    case Dict.get username state.localStates of
        Nothing ->
            ( state, CENoOp )

        Just localState_ ->
            let
                ( localState, editEvent ) =
                    NetworkModel.applyEditorOperations [ op ] localState_
            in
            ( { state | localStates = Dict.insert username localState state.localStates }, ApplyEventToLocalState username editEvent )


init : DocId -> List UserData -> String -> State
init docId users content =
    { localStates = Dict.fromList (List.map2 (\a b -> ( a, b )) (List.map .username users) (List.map (setLocalState docId content) users))
    , server = startSession docId users content initialServer
    }
