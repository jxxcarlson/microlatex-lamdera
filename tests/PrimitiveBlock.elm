module PrimitiveBlock exposing (aIN, aTRANS, bIN, bTRANS, bll, bllc, cIN, eIN, eTRANS, err1, p1, p2, p2Indented, p3, p3Indented, p4Indented, s1, suite, suite3, test_, x2, x2Indent, xIN)

import Expect exposing (..)
import Markup
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock exposing (parse)
import Test exposing (..)


bll str =
    parse L0Lang Markup.isVerbatimLine (String.lines str)


bllc str =
    parse L0Lang Markup.isVerbatimLine (String.lines str) |> List.map .content


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
        , test_ "two paragraphs indented content, second line" (bllc "abc\n  def\n\nghi\n    jkl") [ [ "abc", "def" ], [ "ghi", "jkl" ] ]
        , test_ "two paragraphs, indented content, first line, first paragraph" (bll "  abc\ndef\n\nghi\njkl" |> List.map .indent) [ 2, 0 ]
        , test_ "s1" (bllc s1) [ [ "abc", "def" ], [ "ghi", "jkl" ] ]
        ]



--suite2 : Test
--suite2 =
--    describe "indenter and transformer 2"
--        [ test_ "simple block" (indent_ aIN) (String.lines aIN)
--        , test_ "simple block, transformed" (transform aIN) (String.lines aTRANS)
--        , test_ "block + paragraph" (indent_ bIN) (String.lines bIN)
--        , test_ "block + paragraph, transformed" (transform bIN) (String.lines bTRANS)
--        , test_ "nested microLaTeX blocks" (indent_ cIN) (String.lines cIN)
--        , test_ "nested microLaTeX blocks, transform" (transform cIN) [ "| theorem", "  abc", "", "  $$", "  x^2", "  $$", "", "  def", "" ]
--        , test_ "code block, transform" (transform eIN) (String.lines eTRANS)
--        , test_ "p1" (indent_ p1) (String.lines p1)
--        , test_ "p2" (indent_ p2) (String.lines p2Indented)
--        ]


suite3 : Test
suite3 =
    describe "indenter and transformer"
        [ test_ "foo" 1 1
        ]


err1 =
    """\\begin{theorem}
There are infinitely many primes.

This is a test
"""


p4Indented =
    """\\begin{A}
PQR
STU

  $$
  x^2
  $$

ABC
DEF
\\end{A}
"""


p3 =
    """abc
def

\\begin{A}
PQR
STU
\\end{A}

ghi
jkl
"""


p3Indented =
    """abc
def

  \\begin{A}
  PQR
  STU
  \\end{A}

ghi!!
jkl
"""


p2 =
    """abc
def

ghi
jkl
"""


p2Indented =
    """abc
def

ghi
jkl
"""


p1 =
    """abc
def
"""


x2 =
    """
\\begin{theorem}
There are infinitely
many primes

\\begin{equation}
p \\equiv 1\\ mod\\ 4
\\end{equation}

abc
def
\\end{theorem}
"""


x2Indent =
    """
\\begin{theorem}
There are infinitely
many primes

  \\begin{equation}
  p \\equiv 1\\ mod\\ 4
  \\end{equation}

  abc
  def
\\end{theorem}
"""


aIN =
    """
\\begin{A}
abc
def
\\end{A}
"""


aTRANS =
    """
| A
abc
def

"""


bIN =
    """
\\begin{A}
abc
def
\\end{A}

ghi
jkl
"""


bTRANS =
    """
| A
abc
def


ghi
jkl
"""


xIN =
    "\\begin{A}\n  aaa\n  \n  \\begin{B}\n  bbb\n  \\end{B}\n  \n   ccc\n\\end{A}"


cIN =
    "\\begin{theorem}\n  abc\n  \n  $$\n  x^2\n  $$\n  \n  def\n\\end{theorem}"


eIN =
    """
\\begin{code}
abc
def
\\end{code}
"""


eTRANS =
    """
|| code
abc
def

"""


s1 =
    """
abc
def

ghi
jkl
"""
