module PrimitiveBlock exposing (..)

import Expect exposing (..)
import Markup
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock, blockListOfStringList)
import Parser.TransformLaTeX exposing (indentStrings, transformToL0Aux)
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


indent_ str =
    indentStrings (String.lines str)


transform str =
    indentStrings (String.lines str) |> transformToL0Aux


suite2 : Test
suite2 =
    describe "indenter and transformer 2"
        [ test_ "simple block" (indent_ aIN) (String.lines aIN)
        , test_ "simple block, transformed" (transform aIN) (String.lines aTRANS)
        , test_ "block + paragraph" (indent_ bIN) (String.lines bIN)
        , test_ "block + paragraph, transformed" (transform bIN) (String.lines bTRANS)
        , test_ "nested microLaTeX blocks" (indent_ cIN) (String.lines cOUT)
        , test_ "nested microLaTeX blocks, transform" (transform cIN) (String.lines cTRANS)
        , test_ "nested microLaTeX blocks, missing end" (indent_ dIN) (String.lines dOut)
        , test_ "nested microLaTeX blocks, missing end, transform" (transform dIN) (String.lines dTRANS)
        , test_ "code block, transform" (transform eIN) (String.lines eTRANS)
        , test_ "x1, indented" (indent_ x1) (String.lines x1Indent)
        ]


suite3 : Test
suite3 =
    describe "indenter and transformer"
        [ test_ "block + paragraph" (indent_ bIN) (String.lines bIN)
        ]


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


x1 =
    """
\\begin{theorem}
There are infinitely many primes

$$
p \\equiv 1\\ mod\\ 4
$$
\\end{theorem}
"""


x1Indent =
    """
\\begin{theorem}
There are infinitely many primes

  $$
  p \\equiv 1\\ mod\\ 4

\\end{theorem}
"""


x1TRANS =
    """
| theorem
There are infinitely many primes

  $$
  p \\equiv 1\\ mod\\ 4


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


cIN =
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


cOUT =
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


cTRANS =
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


dIN =
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
"""


dOut =
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

unmatched block A"""


dTRANS =
    """
| A
abc
def

  | B
  ghi
  jkl


mno
pqr

unmatched block A"""


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
