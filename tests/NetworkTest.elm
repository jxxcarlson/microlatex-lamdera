module NetworkTest exposing (..)

import Expect exposing (..)
import NetworkModel exposing (EditEvent, NetworkModel)
import NetworkSimulator
import OT exposing (Document, Operation(..))
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
    [ { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    ]


events2 =
    [ { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "DE" ] }
    , { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Delete 1 ] }
    ]


events3 =
    [ { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "DE" ] }
    , { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Delete 1 ] }
    , { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Skip -4 ] }
    , { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "X" ] }
    ]


events4 =
    [ { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
    , { userId = "b", dp = -3, dx = -3, dy = 0, operations = [ Insert "X" ] }
    ]


events5 =
    [ { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Insert "A" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "B" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "C" ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "DE" ] }
    , { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Skip -1 ] }
    , { userId = "a", dp = 0, dx = 0, dy = 0, operations = [ Delete 1 ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Skip -3 ] }
    , { userId = "b", dp = 0, dx = 0, dy = 0, operations = [ Insert "XY" ] }
    ]
