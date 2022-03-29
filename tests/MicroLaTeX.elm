module MicroLaTeX exposing (..)

import Expect exposing (..)
import MicroLaTeX.Parser.TransformLaTeX exposing (toL0Aux)
import Test exposing (..)


f str =
    toL0Aux (String.lines str)


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "MicroLaTeX, toL0"
        [ test_ "x1" (f x1) [ "", "\\title{MicroLaTeX Test}", "", "abc", "", "def", "" ]
        , test_ "x2" (f x2) [ "", "|| equation", "\\int_0^1 x^n dx = \\frac{1}{n+1}", "", "" ]
        , test_ "section" (f section) [ "", "\\section{Intro}", "", "\\subsection{Foobar}", "" ]
        , test_ "item" (f item) [ "", "| item", "Foo bar", "" ]
        , test_ "theorem" (f "\n\\begin{theorem}\nHo ho ho\n\\end{theorem}\n") [ "", "| theorem", "Ho ho ho", "", "" ]
        , test_ "theorem, unterminated" (f "\n\\begin{theorem}\nHo ho ho\n") [ "", "| theorem", "Ho ho ho", "\\red{^^^ missing end tag (2)}", "" ]
        ]


x1 =
    """
\\title{MicroLaTeX Test}

abc

def
"""


x2 =
    """
\\begin{equation}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}
"""


item =
    """
\\item
Foo bar
"""


section =
    """
\\section{Intro}

\\subsection{Foobar}
"""
