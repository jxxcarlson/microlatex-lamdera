module OTSimulatorTest exposing (..)

import CollaborativeEditing.NetworkModel exposing (EditEvent, NetworkModel)
import CollaborativeEditing.NetworkSimulator2 as NetworkSimulator exposing (EditOp(..), SUser(..), run)
import CollaborativeEditing.OT exposing (Document, Operation(..))
import Expect exposing (..)
import Test exposing (..)
import Dict exposing(Dict)


test_ label expr expected =
    test label <| \_ -> equal expr expected) True


suite : Test
Test.only <| suite =
    describe "NetworkModel Simulator"
        [ test_ "a inserts A, then b insert B" run1.a out1
        ]


run1 =
    run "abcd" [ { user = UserA, op = EMoveCursor 4 }, { user = UserA, op = EInsert 4 "X" } ]

out1 = { editor = { content = "abcdXX", cursor = 5, id = "doc" }, model = { localMsgs = [], serverState = { cursorPositions = Dict.fromList [("A",6),("B",0)], document = { content = "abcdXX", cursor = 5, id = "doc" } } }, user = UserA }