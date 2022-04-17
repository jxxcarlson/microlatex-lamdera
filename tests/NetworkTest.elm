module NetworkTest exposing (suite)

import Expect exposing (..)
import Network exposing (..)
import Test exposing (..)


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "Network test"
        [ test_ "insert, 'x' at beginning" 1 1
        ]
