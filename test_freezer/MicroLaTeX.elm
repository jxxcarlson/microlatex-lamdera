module MicroLaTeX exposing (suite, suite3)

import Expect exposing (..)
import MicroLaTeX.Parser.Expression exposing (parse)
import MicroLaTeX.Parser.TransformLaTeX exposing (toL0Aux)
import Parser.Expr exposing (Expr(..))
import Test exposing (..)


p str =
    parse 0 str


f str =
    toL0Aux (String.lines str)


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "MicroLaTeX, toL0"
        [ test_ "x1" (f x1) [ "", "\\title{MicroLaTeX OTNetworkTest}", "", "abc", "", "def", "" ]
        , test_ "x2" (f x2) [ "", "|| equation", "\\int_0^1 x^n dx = \\frac{1}{n+1}", "", "" ]
        , test_ "section" (f section) [ "", "\\section{Intro}", "", "\\subsection{Foobar}", "" ]
        , test_ "item" (f item) [ "", "| item", "Foo bar", "" ]
        , test_ "theorem" (f "\n\\begin{theorem}\nHo ho ho\n\\end{theorem}\n") [ "", "| theorem", "Ho ho ho", "", "" ]
        , test_ "theorem, missmatched" (f "\n\\begin{theorem}\nHo ho ho\n\\end{the}\n") [ "", "| theorem", "Ho ho ho", "", "\\red{^^^ missmatched end tags}", "" ]
        , test_ "theorem, unterminated" (f "\n\\begin{theorem}\nHo ho ho\n") [ "", "| theorem", "Ho ho ho", "\\red{^^^ missing end tag (2)}", "" ]
        , test_ "equation, then aligned" (f "\n\\begin{equation}\nx^2\n\\end{equation}\n\n\\begin{aligned}\na &= x + y \\\\\n\\end{aligned}\n") [ "", "|| equation", "x^2", "", "", "|| aligned", "a &= x + y \\\\", "", "" ]
        , test_ "block inside code block" (f "\n\\begin{code}\n\\begin{mathmacros}\n\\newcommand{\\bra}[0]{\\]langle}\n\\end{mathmacros}\n\\end{code}\n") [ "", "|| code", "\\begin{mathmacros}", "\\newcommand{\\bra}[0]{\\]langle}", "\\end{mathmacros}", "", "" ]
        ]


suite2 : Test
suite2 =
    describe "MicroLaTeX Parser"
        [ test_ "just text" (p "foo") ( [ Text "foo" { begin = 0, end = 2, id = "0.0", index = 0 } ], [] )
        , test_ "one macro" (p "\\italic{stuff}") ( [ Expr "italic" [ Text "stuff" { begin = 8, end = 12, id = "8.3", index = 3 } ] { begin = 0, end = 0, id = "0.0", index = 0 } ], [] )
        , test_ "nested" (p "\\italic{\\bold{stuff}}") ( [ Expr "italic" [ Expr "bold" [ Text "stuff" { begin = 14, end = 18, id = "14.6", index = 6 } ] { begin = 8, end = 8, id = "8.3", index = 3 } ] { begin = 0, end = 0, id = "0.0", index = 0 } ], [] )
        , test_ "text + macro" (p "foo \\italic{stuff} bar") ( [ Text "foo " { begin = 0, end = 3, id = "0.3", index = 0 }, Expr "italic" [ Text "stuff" { begin = 12, end = 16, id = "12.4", index = 4 } ] { begin = 4, end = 4, id = "4.0", index = 1 }, Text " bar" { begin = 18, end = 21, id = "18.21", index = 6 } ], [] )
        , test_ "two arguments" (p "\\f{x}{y}") ( [ Expr "f" [ Text "x" { begin = 3, end = 3, id = "3.3", index = 3 }, Text "y" { begin = 6, end = 6, id = "6.6", index = 6 } ] { begin = 0, end = 0, id = "0.0", index = 0 } ], [] )
        , test_ "error, unclosed argument" (p "\\italic{") ( [ Expr "errorHighlight" [ Text "\\italic{" { begin = 0, end = 0, id = "dummy (3)", index = 0 } ] { begin = 0, end = 0, id = "dummy (3)", index = 0 } ], [ "Missing right brace, column 7 (line 0)" ] )
        , test_ "error, unclosed argument abc" (p "\\italic{abc") ( [ Expr "errorHighlight" [ Text "\\italic{" { begin = 0, end = 0, id = "dummy (3)", index = 0 } ] { begin = 0, end = 0, id = "dummy (3)", index = 0 }, Text "abc" { begin = 8, end = 10, id = "8.3", index = 3 } ], [ "Missing right brace, column 7 (line 0)" ] )
        ]


suite3 : Test
suite3 =
    describe "MicroLaTeX Parser"
        [ test_ "two arguments" (p "\\f{x}{y}") ( [ Expr "f" [ Text "x" { begin = 3, end = 3, id = "3.3", index = 3 }, Text "y" { begin = 6, end = 6, id = "6.6", index = 6 } ] { begin = 0, end = 0, id = "0.0", index = 0 } ], [] )
        ]


x1 =
    """
\\title{MicroLaTeX OTNetworkTest}

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
