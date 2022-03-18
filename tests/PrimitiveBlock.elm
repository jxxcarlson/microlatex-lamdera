module PrimitiveBlock exposing (..)

import Expect exposing (..)
import Markup
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock, blockListOfStringList, indentStrings, transformToL0Aux)
import Test exposing (..)


bll str =
    blockListOfStringList L0Lang Markup.isVerbatimLine (String.lines str)


bllc str =
    blockListOfStringList L0Lang Markup.isVerbatimLine (String.lines str) |> List.map .content


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput



{-
   FOR THE MOMENT: sequences of two or more newlines parse to [""].
   That way there is an efficient representation of the end-of-block marker.
   Not sure if this is a good idea.


-}


suite : Test
suite =
    describe "The primitive block parser"
        [ test_ "two paragraphs, no indentation" (bllc "abc\ndef\n\nghi\njkl") [ [ "abc", "def" ], [ "ghi", "jkl" ] ]
        , test_ "two paragraphs, a run of newlines" (bllc "abc\ndef\n\n\n\nghi\njkl") [ [ "abc", "def" ], [ "ghi", "jkl" ] ]
        , test_ "two paragraphs indented content, second line" (bllc "abc\n  def\n\nghi\n    jkl") [ [ "abc", "  def" ], [ "ghi", "    jkl" ] ]
        , test_ "two paragraphs, indented content, first line, first paragraph"
            (bll "  abc\ndef\n\nghi\njkl" |> List.map .indent)
            [ 2, 0 ]
        , test_ "s1" (bllc s1) [ [ "abc", "def" ], [ "ghi", "jkl" ] ]
        ]


suite2 : Test
suite2 =
    describe "indenter and trasnformer"
        [ test_ "simplest case" (indentStrings (String.lines i1IN)) (String.lines i1OUT)
        , test_ "simplest case, transformed" (indentStrings (String.lines i1IN) |> transformToL0Aux) (String.lines i1TRANS)
        ]


i1IN =
    """
\\begin{A}
abc
def

\\begin{B}
ghi
jkl
\\end{B}

mno
pqr
\\end{A}
"""


i1OUT =
    """
\\begin{A}
abc
def

  \\begin{B}
  ghi
  jkl
  \\end{B}

mno
pqr
\\end{A}
"""


i1TRANS =
    """
| A
abc
def

  | B
  ghi
  jkl

mno
pqr
"""


s1 =
    """
abc
def

ghi
jkl
"""
