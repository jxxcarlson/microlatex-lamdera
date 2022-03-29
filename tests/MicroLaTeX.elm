module MicroLaTeX exposing (..)

import Compiler.Util exposing (depth, size)
import Expect exposing (..)
import Markup
import MicroLaTeX.Parser.TransformLaTeX exposing (indentStrings, toL0Aux, toL0Aux2)
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock, parse)
import Test exposing (..)


f str =
    toL0Aux2 (String.lines str)


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "MicroLaTeX, toL0"
        [ test_ "x1" (f x1) [ "", "\\title{MicroLaTeX Test}", "", "abc", "", "def", "" ]
        , test_ "x2" (f x2) [ "", "|| equation", "\\int_0^1 x^n dx = \\frac{1}{n+1}", "", "" ]
        , test_ "section" (f section) [ "", "\\section{Intro}", "", "\\subsection{Foobar}", "" ]
        , test_ "item" (f item) [ "", "| item", "Foo bar", "" ]
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
