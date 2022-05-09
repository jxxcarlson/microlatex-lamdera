module OTSimulatorTest exposing (suite)

import CollaborativeEditing.NetworkModel2
    exposing
        ( applyEditorOperations
        , applyEventToLocalState
        , initialServer
        , removeSession
        , sendChanges
        , setLocalState
        , startSession
        )
import CollaborativeEditing.OT exposing (Document, Operation(..))
import Deque exposing (Deque)
import Dict
import Expect exposing (..)
import Test exposing (..)


test_ label expr expected =
    test label <| \_ -> equal expr expected


suite : Test
suite =
    describe "NetworkModel Simulator"
        [ test_ "initializeServer, start and remove session"
            (initialServer |> startSession "doc" users "" |> removeSession "doc")
            initialServer
        , test_ "Insert 'abc' at cursor = 0" s1.localModel.localDocument { content = "abc", cursor = 3, docId = "doc" }
        , test_ "sendChanges"
            (sendChanges ( s1, server0 )
                |> Tuple.second
                |> .pendingChanges
                |> Dict.get "doc"
                |> Maybe.andThen Deque.first
                |> Maybe.map Tuple.second
            )
            (Just { cursorChange = 3, operations = [ Insert 0 "abc" ] })
        ]


userA =
    { username = "Alice", clientId = "1" }


userB =
    { username = "Bob", clientId = "2" }


users =
    [ userA, userB ]


server0 =
    initialServer |> startSession "doc" users ""


s0 =
    setLocalState "doc" "" userA


s1 =
    s0
        |> applyEditorOperations [ Insert 0 "abc" ]
        |> applyEventToLocalState
        |> Tuple.first
