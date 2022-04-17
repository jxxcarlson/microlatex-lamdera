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
        [ test_ "scenario 1, event" (createEvent scenario1) { dp = 1, dx = 1, dy = 0, operations = [ Insert "A" ], userId = "bozo" }
        , test_ "scenario 1, reconcile" (reconcile scenario1) scenario1.new
        ]



-- SCENARIO 1


type alias Scenario =
    { old : OT.Document, new : OT.Document }


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


scenario1 =
    { old = { cursor = 0, x = 0, y = 0, content = "" }
    , new = { cursor = 1, x = 1, y = 0, content = "A" }
    }
