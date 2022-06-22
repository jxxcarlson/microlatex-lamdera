module CollaborativeEditing.NetworkSimulator exposing (..)

-- (eventStream1, pass, runWithInput)

import CollaborativeEditing.NetworkModel as NetworkModel exposing (EditEvent, NetworkModel)
import CollaborativeEditing.OT exposing (Operation(..))
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
    { a = NetworkModel.initWithUsersAndContent "x" [ "a", "b" ] "", b = NetworkModel.initWithUsersAndContent "x" [ "a", "b" ] "", server = [], input = events, count = 0 }


pass : State -> Bool
pass state =
    NetworkModel.getLocalDocument state.a == NetworkModel.getLocalDocument state.b


{-|

    > runWithInput eventStream1 |> pass
    True : Bool

-}
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
                | a = NetworkModel.updateFromBackend NetworkModel.applyEvent evt state.a
                , b = NetworkModel.updateFromBackend NetworkModel.applyEvent evt state.b
                , server = List.drop 1 state.server
            }


update : EditEvent -> State -> State
update event state =
    state
        |> updatePhase1 event
        |> updatePhase2
        |> (\st -> { st | count = st.count + 1 })


events1 =
    [ { userId = "a", docId = "1", dp = 0, operations = [ Insert 0 "A" ] }
    , { userId = "b", docId = "1", dp = 0, operations = [ Insert 0 "B" ] }
    ]


events2 =
    [ { userId = "a", docId = "1", dp = 0, operations = [ Insert 0 "A" ] }
    , { userId = "b", docId = "1", dp = 0, operations = [ Insert 0 "B" ] }
    , { userId = "b", docId = "1", dp = 0, operations = [ Insert 2 "X" ] }
    ]



--
--events2 =
--    [ { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "DE" ] }
--    , { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Delete 1 ] }
--    ]
--
--
--events3 =
--    [ { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "DE" ] }
--    , { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ MoveCursor -1 ] }
--    , { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Delete 1 ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ MoveCursor -3 ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "XY" ] }
--    ]
--
--
--events4 =
--    [ { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
--    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
--    , { userId = "b", dp = -3, dx = -3, dy = 0, operations = [ Insert "X" ] }
--    ]
