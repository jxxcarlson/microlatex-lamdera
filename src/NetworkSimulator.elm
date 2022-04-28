module NetworkSimulator exposing (eventStream1, pass, runWithInput)

import Network exposing (EditEvent, NetworkModel)
import OT exposing (Operation(..))
import Util exposing (Step(..), loop)


type alias State =
    { a : NetworkModel
    , b : NetworkModel
    , server : List EditEvent
    , input : List EditEvent
    , count : Int
    }


init : List EditEvent -> State
init events =
    { a = Network.initWithUsersAndContent [ "a", "b" ] "", b = Network.initWithUsersAndContent [ "a", "b" ] "", server = [], input = events, count = 0 }


pass : State -> Bool
pass state =
    Network.getLocalDocument state.a == Network.getLocalDocument state.b


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
                | a = Network.updateFromBackend Network.applyEvent evt state.a
                , b = Network.updateFromBackend Network.applyEvent evt state.b
                , server = List.drop 1 state.server
            }


update : EditEvent -> State -> State
update event state =
    state
        |> updatePhase1 event
        |> updatePhase2
        |> (\st -> { st | count = st.count + 1 })
