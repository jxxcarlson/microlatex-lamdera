module OTSimulatorTest exposing (..)

import CollaborativeEditing.NetworkModel exposing (EditEvent, NetworkModel)
import CollaborativeEditing.NetworkSimulator2 as NetworkSimulator exposing (SUser(..), performEdit, run)
import CollaborativeEditing.OT exposing (Document, Operation(..))
import Dict exposing (Dict)
import Expect exposing (..)
import Test exposing (..)


test_ label expr expected =
    test label <| \_ -> equal expr expected


suite : Test
suite =
    describe "NetworkModel Simulator"
        [ test_ "move to end, add one letter" out1.a result1
        , test_ "add one letter at beginning" out2.a result2
        , test_ "delete one letter at beginning" out3.a result3
        ]


out1 =
    NetworkSimulator.initialState "abcd"
        |> performEdit { user = UserA, op = MoveCursor 4 }
        |> performEdit { user = UserA, op = Insert 4 "X" }


out2 =
    NetworkSimulator.initialState "abcd"
        |> performEdit { user = UserA, op = Insert 0 "X" }


out3 =
    NetworkSimulator.initialState "abcd"
        |> performEdit { user = UserA, op = Delete 0 2 }


result1 =
    { editor = { content = "abcdX", cursor = 5, id = "doc" }
    , model =
        { localMsgs =
            [ { docId = "doc"
              , dp = 1
              , operations = [ Insert 4 "X" ]
              , userId = "A"
              }
            ]
        , serverState =
            { cursorPositions = Dict.fromList [ ( "A", 5 ), ( "B", 0 ) ]
            , document = { content = "abcdX", cursor = 5, id = "doc" }
            }
        }
    , user = UserA
    }


result2 =
    { editor = { content = "Xabcd", cursor = 1, id = "doc" }
    , model =
        { localMsgs =
            [ { docId = "doc"
              , dp = 1
              , operations = [ Insert 0 "X" ]
              , userId = "A"
              }
            ]
        , serverState =
            { cursorPositions = Dict.fromList [ ( "A", 1 ), ( "B", 0 ) ]
            , document = { content = "Xabcd", cursor = 1, id = "doc" }
            }
        }
    , user = UserA
    }


result3 =
    { editor = { content = "cd", cursor = 0, id = "doc" }
    , model =
        { localMsgs =
            [ { docId = "doc"
              , dp = 0
              , operations = [ Delete 0 2 ]
              , userId = "A"
              }
            ]
        , serverState =
            { cursorPositions = Dict.fromList [ ( "A", 0 ), ( "B", 0 ) ]
            , document = { content = "cd", cursor = 0, id = "doc" }
            }
        }
    , user = UserA
    }



--run2 =
--    run "abcd" [ { user = UserA, op = MoveCursor 4 }, { user = UserA, op = Insert 4 "X" } ]
--
--
--out2 =
--    { editor = { content = "abcdX", cursor = 5, id = "doc" }, model = { localMsgs = [], serverState = { cursorPositions = Dict.fromList [ ( "A", 5 ), ( "B", 0 ) ], document = { content = "abcdX", cursor = 5, id = "doc" } } }, user = UserA }
