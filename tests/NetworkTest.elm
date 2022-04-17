module NetworkTest exposing (suite)

import Expect exposing (..)
import Network exposing (..)
import OT exposing (Operation(..))
import Test exposing (..)


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "Network test"
        [ test_ (name insertAtBeginning "event") (createEvent insertAtBeginning) { dp = 1, dx = 1, dy = 0, operations = [ Insert "A" ], userId = "bozo" }
        , test_ (name insertAtBeginning "reconcile") (reconcile insertAtBeginning) insertAtBeginning.new
        , test_ (name insertAtEnd "event") (createEvent insertAtEnd) { dp = 1, dx = 1, dy = 0, operations = [ Insert "B" ], userId = "bozo" }
        , test_ (name insertAtEnd "reconcile") (reconcile insertAtEnd) insertAtEnd.new
        , test_ (name insertInMiddle "event") (createEvent insertInMiddle) { dp = 1, dx = 1, dy = 0, operations = [ Insert "X" ], userId = "bozo" }
        , test_ (name insertInMiddle "reconcile") (reconcile insertInMiddle) insertInMiddle.new
        , test_ (name deleteInMiddle "event") (createEvent deleteInMiddle) { dp = 0, dx = 0, dy = 0, operations = [ Delete 1 ], userId = "bozo" }
        , test_ (name deleteAtEnd "event") (createEvent deleteAtEnd) { dp = -1, dx = -1, dy = 0, operations = [ Skip 0, Delete 1 ], userId = "bozo" }
        , test_ (name deleteAtEnd "reconcile") (reconcile deleteAtEnd) deleteAtEnd.new
        ]


name : Scenario -> String -> String
name scenario tag =
    scenario.name ++ " " ++ tag



-- SCENARIO 1


type alias Scenario =
    { name : String, old : OT.Document, new : OT.Document }


dummyEvent =
    { userId = "bozo", dp = 0, dx = 0, dy = 0, operations = [] }


createEvent : Scenario -> Network.EditEvent
createEvent scenario =
    Network.createEvent "bozo" scenario.old scenario.new


reconcile : Scenario -> OT.Document
reconcile scenario =
    let
        event =
            createEvent scenario
    in
    OT.apply event.operations scenario.old


insertAtBeginning =
    { name = "1, insert at beginning"
    , old = { cursor = 0, x = 0, y = 0, content = "" }
    , new = { cursor = 1, x = 1, y = 0, content = "A" }
    }


insertInMiddle =
    { name = "2 insert in middle"
    , old = { cursor = 1, x = 1, y = 0, content = "AB" }
    , new = { cursor = 2, x = 2, y = 0, content = "AXB" }
    }


insertAtEnd =
    { name = "3, insert at end"
    , old = { cursor = 1, x = 1, y = 0, content = "A" }
    , new = { cursor = 2, x = 2, y = 0, content = "AB" }
    }


deleteInMiddle =
    { name = "delete (middle)"
    , old = { cursor = 1, x = 1, y = 0, content = "ABC" }
    , new = { cursor = 1, x = 1, y = 0, content = "AC" }
    }


deleteAtEnd =
    { name = "delete (end)"
    , old = { cursor = 2, x = 2, y = 0, content = "ABC" }
    , new = { cursor = 1, x = 1, y = 0, content = "AB" }
    }
