module MatchTests exposing (..)

import Expect exposing (..)
import L0.Parser.Match exposing (reducible)
import L0.Parser.Symbol exposing (Symbol(..))
import Test exposing (..)


test_ label expr expected =
    test label <| \_ -> equal expr expected


suite : Test
suite =
    describe "Match"
        [ test_ "[L, R]" (reducible [ L, R ]) True
        , test_ "[L, L, ST, R]" (reducible [ L, L, ST, R ]) False
        , test_ "[M, ST, M]" (reducible [ M, ST, M ]) True
        ]
