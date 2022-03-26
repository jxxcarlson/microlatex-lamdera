module MicroLaTeXPB exposing (..)

import Compiler.Util exposing (depth, size)
import Expect exposing (..)
import MicroLaTeX.Parser.Line as Line exposing (Line, PrimitiveBlockType(..))
import MicroLaTeX.Parser.PrimitiveBlock exposing (toPrimitiveBlocks)
import Parser.TextMacro exposing (MyMacro(..))
import Test exposing (..)


f str =
    toPrimitiveBlocks (\_ -> False) (String.lines str)


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "toPrimitiveBlocks, experimental"
        [ test_ "a1" (f a1) a1out
        ]


suite1 : Test
suite1 =
    describe "toPrimitiveBlocks"
        [ test_ "a1" (f a1) a1out
        , test_ "a1, length" (f a1 |> List.length) 2
        , test_ "a1, type" (f a1 |> List.map .blockType) [ PBParagraph, PBParagraph ]
        , test_ "a1, name" (f a1 |> List.map .name) [ Nothing, Nothing ]
        , test_ "a1, indent" (f a1 |> List.map .indent) [ 0, 0 ]

        --
        , test_ "a2, indent" (f a2 |> List.map .indent) [ 0, 2 ]

        --
        , test_ "a3, length" (f a3 |> List.length) 1
        , test_ "a3, type" (f a3 |> List.map .blockType) [ PBOrdinary ]
        , test_ "a3, name" (f a3 |> List.map .name) [ Just "theorem" ]
        , test_ "a3, content" (f a3 |> List.map .content) [ [ "| theorem", "abc", "def", "" ] ]
        , test_ "a3, indent" (f a3 |> List.map .indent) [ 0 ]
        ]


a1 =
    """
abc
def

ghi
jkl
"""


a1out =
    [ { args = [], blockType = PBParagraph, content = [ "abc", "def" ], indent = 0, lineNumber = 2, name = Nothing, named = True, position = 1, sourceText = "abc\ndef" }, { args = [], blockType = PBParagraph, content = [ "ghi", "jkl" ], indent = 0, lineNumber = 5, name = Nothing, named = True, position = 7, sourceText = "ghi\njkl" } ]


a2 =
    """
abc
def

  ghi
  jkl
"""


a3 =
    """
\\begin{theorem}
abc
def
\\end{theorem}
"""


a4 =
    """
\\begin{theorem}
This is a very good theorem

  $$
  x^2
  $$

  Isn't that nice?

\\end{theorem}
"""
