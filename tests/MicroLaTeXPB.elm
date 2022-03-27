module MicroLaTeXPB exposing (..)

import Compiler.Util exposing (depth, size)
import Expect exposing (..)
import MicroLaTeX.Parser.Line as Line exposing (Line, PrimitiveBlockType(..))
import MicroLaTeX.Parser.PrimitiveBlock exposing (toPrimitiveBlocks)
import Parser.TextMacro exposing (MyMacro(..))
import Test exposing (..)


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
