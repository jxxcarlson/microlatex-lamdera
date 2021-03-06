module NetworkTest exposing (..)

import CollaborativeEditing.NetworkModel exposing (EditEvent, NetworkModel)
import CollaborativeEditing.NetworkSimulator as NetworkSimulator
import CollaborativeEditing.OT exposing (Document, Operation(..))
import Expect exposing (..)
import Test exposing (..)


test_ : String -> List EditEvent -> Test
test_ label events =
    test label <| \_ -> equal (NetworkSimulator.runWithInput events |> NetworkSimulator.pass) True


suite : Test
suite =
    describe "NetworkModel Simulator"
        [ test_ "a inserts A, then b insert B" events1
        , test_ "a inserts A, then b insert B, ..., a deletes 1" events2
        , test_ "a inserts A, then b insert B, ..., a deletes 1, a skips -4 and inserts X" events3
        , test_ "use some negative offsets" events4
        , test_ "XYABCD" events5
        ]


events1 =
    [ { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    ]


events1a =
    [ { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    ]


events2 =
    [ { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "DE" ] }
    , { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Delete 1 ] }
    ]


events3 =
    [ { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "DE" ] }
    , { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Delete 1 ] }
    , { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ MoveCursor -4 ] }
    , { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "X" ] }
    ]


events4 =
    [ { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
    , { docId = "x", userId = "b", dp = -3, dx = -3, dy = 0, operations = [ Insert "X" ] }
    ]


events5 =
    [ { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "DE" ] }
    , { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ MoveCursor -1 ] }
    , { docId = "x", userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Delete 1 ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ MoveCursor -3 ] }
    , { docId = "x", userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "XY" ] }
    ]
