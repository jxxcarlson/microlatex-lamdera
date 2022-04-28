module NetworkSimulator exposing (..)

import Network exposing (EditEvent, NetworkModel)
import OT exposing (Operation(..))
import Util exposing (Step(..), loop)


type alias State =
    { a : NetworkModel, b : NetworkModel, server : List EditEvent, input : List EditEvent, count : Int }


init : List EditEvent -> State
init events =
    { a = Network.initWithUsersAndContent [ "a", "b" ] "" |> Debug.log "INIT (a)", b = Network.initWithUsersAndContent [ "a", "b" ] "" |> Debug.log "INIT (b)", server = [], input = events, count = 0 }


eventStream1 =
    [ { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    ]


runWithInput : List EditEvent -> State
runWithInput events =
    run (init events)


run : State -> State
run state =
    loop state nextStep


nextStep : State -> Step State State
nextStep state =
    case List.head state.input of
        Nothing ->
            Done state

        Just event ->
            Loop (update event { state | input = List.drop 1 state.input })


updatePhase1 : EditEvent -> State -> State
updatePhase1 event state =
    { state | server = event :: state.server }


updatePhase2 : State -> State
updatePhase2 state =
    case List.head state.server of
        Nothing ->
            state

        Just evt ->
            { state
                | a = Network.updateFromBackend Network.applyEvent (Debug.log "EVT (a)" evt) state.a |> Debug.log "UPDATE BE, A"
                , b = Network.updateFromBackend Network.applyEvent (Debug.log "EVT (b)" evt) state.b |> Debug.log "UPDATE BE, B"
                , server = List.drop 1 state.server
            }


update : EditEvent -> State -> State
update event state =
    let
        _ =
            Debug.log "n" state.count
    in
    state
        |> updatePhase1 event
        |> Debug.log ("Phase I: " ++ String.fromInt state.count)
        |> updatePhase2
        |> (\st -> { st | count = st.count + 1 })
        |> Debug.log ("Phase II: " ++ String.fromInt state.count)
