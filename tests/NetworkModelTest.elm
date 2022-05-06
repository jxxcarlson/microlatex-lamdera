module NetworkModelTest exposing (..)


import Expect exposing (..)
import OT exposing (Document, Operation(..))
import Test exposing (..)
import NetworkModel

doc1a =  { id ="1", cursor = 0, x = 0, y = 0, content = "abcd" }
doc1b = { id ="1", cursor = 3, x = 3, y = 0, content = "abcd" }
event1 =
    { docId = "1", userId = "x", dp = 3, dx = 3, dy = 0,operations = [OTNoOp] }




test_ : String -> OT.Document -> OT.Document -> NetworkModel.EditEvent -> Test
test_ label doc1 doc2 event =
    test label <| \_ -> equal (NetworkModel.createEvent "x" doc1 doc2) event


suite : Test
suite =
    describe "test createEvent"
        [ test_ "1" doc1a doc1b event1

        ]
