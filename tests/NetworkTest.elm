module NetworkTest exposing (..)

import Expect exposing (..)
import Network exposing (NetworkModel)
import NetworkSimulator
import OT exposing (Document, Operation(..))
import Test exposing (..)


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "OT scenario"
        [ test_ "User A inserts 'a' at beginning" docA2 { cursor = 1, x = 1, y = 0, content = "a" }
        , test_ "User B inserts 'x' at beginning" docB2 { cursor = 1, x = 1, y = 0, content = "x" }
        , test_ "User B gets update from backend with user A's edit" docB3 { cursor = 2, x = 2, y = 0, content = "ax" }
        ]
