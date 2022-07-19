module MatchTests exposing (..)

import Expect exposing (..)
import L0.Parser.Match exposing (isReducible)
import L0.Parser.Symbol exposing (Symbol(..))
import Test exposing (..)


test_ label expr expected =
    test label <| \_ -> equal expr expected


suite : Test
suite =
    describe "Match"
        [ test_ "[L, R]" (isReducible [ L, R ]) True
        , test_ "[L, L, ST, R]" (isReducible [ L, L, ST, R ]) False
        , test_ "[M, ST, M]" (isReducible [ M, ST, M ]) True
        ]
