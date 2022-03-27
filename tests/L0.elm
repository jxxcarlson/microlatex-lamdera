module L0 exposing (..)

import Compiler.Acc
import Compiler.Util exposing (depth, size)
import Expect exposing (..)
import Markup
import Parser.Block exposing (ExpressionBlock)
import Parser.Forest exposing (Forest)
import Parser.Language exposing (Language(..))
import Parser.Line as Line exposing (Line, PrimitiveBlockType(..))
import Parser.PrimitiveBlock exposing (parse)
import Parser.TextMacro exposing (MyMacro(..))
import Test exposing (..)
import Tree exposing (Tree)


parse : String -> Forest ExpressionBlock
parse str =
    Markup.parse L0Lang str |> Compiler.Acc.transformST L0Lang


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "toPrimitiveBlocks, experimental"
        [ test_ "e1, depth" (parse e1 |> List.map depth) [ 2 ]
        , test_ "e2, depth" (parse e2 |> List.map depth) [ 1 ]
        , test_ "e2, size" (parse e2 |> List.map size) [ 3 ]
        , test_ "e2, children" (parse e2 |> List.map Tree.children |> List.map List.length) [ 2 ]
        , test_ "e3, depth" (parse e3 |> List.map depth) [ 1 ]
        , test_ "e3, size" (parse e3 |> List.map size) [ 4 ]
        , test_ "e3, children" (parse e3 |> List.map Tree.children |> List.map List.length) [ 3 ]
        ]


e1 =
    """
| indent
abc

  | indent
  def

    | indent
    ghi
    
"""


e2 =
    """
| theorem
  This is a very good theorem

  $$
  x^2
  $$

  Isn't that nice?

"""


e3 =
    """
| theorem

  This is a very good theorem

  $$
  x^2
  $$

  Isn't that nice?

"""
