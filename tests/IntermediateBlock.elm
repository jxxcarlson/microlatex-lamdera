module IntermediateBlock exposing (..)

import Compiler.Util exposing (depth, size)
import Expect exposing (..)
import Markup
import Parser.Block exposing (getArgs, getBlockType, getContent, getName)
import Parser.Language exposing (Language(..))
import Test exposing (..)
import Tree


ibl str =
    Markup.parseToIntermediateBlocks L0Lang str


ibm str =
    Markup.parseToIntermediateBlocks MicroLaTeXLang str


ibx str =
    Markup.parseToIntermediateBlocks XMarkdownLang str


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    test_ "one" 1 1



--suite2 : Test
--suite2 =
--    describe "The intermediate block parser"
--        [ test_ "two paragraphs, no indentation" (ibm s1 |> List.length) 2
--        , test_ "two paragraphs, second indented" (ibm s2 |> List.length) 1
--        , test_ "two paragraphs, second indented, depth is 1" (ibm s2 |> List.map depth) [ 1 ]
--        , test_ "two L0 blocks at indent 0" (ibl s3 |> List.length) 2
--        , test_ "two L0 blocks at indent 0, get names" (ibl s3 |> unroll |> List.map getName) [ Just "A", Just "B" ]
--        , test_ "two L0 blocks first at indent 0, second at indent 4" (ibl s4 |> List.length) 1
--        , test_ "two L0 blocks first at indent 0, second at indent 4, getNames" (ibl s4 |> unroll |> List.map getName) [ Just "A", Just "B" ]
--        , test_ "two L0 blocks first at indent 0, second at indent 4, depth is 1" (ibl s4 |> List.map depth) [ 1 ]
--        , test_ "two L0 blocks first at indent 0, second at indent 4, depth is 1, getNames" (ibl s4 |> unroll |> List.map getName) [ Just "A", Just "B" ]
--        , test_ "one microLaTeX Block, depth" (ibm m1 |> List.map depth) [ 0 ]
--        , test_ "one microLaTeX Block, name" (ibm m1 |> unroll |> List.map getName) [ Just "A" ]
--        , test_ "one microLaTeX Block, args" (ibm m1 |> unroll |> List.map getArgs) [ [] ]
--        , test_ "one microLaTeX Block, nontrivial args" (ibm m2 |> unroll |> List.map getArgs) [ [ "X", "Y" ] ]
--        , test_ "one microLaTeX Block, content" (ibm m2 |> unroll |> List.map getContent) [ [ "abc", "def" ] ]
--
--        --, Test.skip <| test_ "one microLaTeX Block, content with blank line" (ibm m3 |> unroll |> List.map getContent) [ [ "abc", "def", "ghi" ] ]
--        ]


suite3 : Test
suite3 =
    describe "The intermediate block parser, XX"
        [ test_ "xx1" (ibm xx1 |> List.map depth) [ 1 ]
        , test_ "xx1b" (ibm xx1b |> List.map depth) [ 1 ]

        -- , test_ "xx2" (ibm xx2 |> List.map depth) [ 1 ]
        ]


xx1 =
    """
\\begin{theorem}
There are infinitely many primes

\\begin{equation}
p \\equiv 1\\ mod\\ 4
\\end{equation}

\\end{theorem}
"""


xx1b =
    """
\\begin{theorem}
There are infinitely many primes

$$
p \\equiv 1\\ mod\\ 4
$$

\\end{theorem}
"""


xx2 =
    """
\\begin{theorem}
There are infinitely many primes

\\begin{equation}
p \\equiv 1\\ mod\\ 4
\\end{equation}

abc
def
\\end{theorem}
"""


unroll : List (Tree.Tree a) -> List a
unroll =
    List.map Tree.flatten >> List.concat


x1 =
    """
\\begin{theorem}
There are infinitely many primes 

$$
p \\equiv 1\\ mod\\ 4
$$

Isn't that nice?
\\end{theorem}
"""


m1 =
    """
\\begin{A}
abc
def
\\end{A}
"""


m2 =
    """
\\begin{A}[X][Y]
abc
def
\\end{A}
"""


m3 =
    """
\\begin{A}[X][Y]
abc
def

ghi
\\end{A}
"""


s1 =
    """
abc
def

ghi
jkl
"""


s2 =
    """
abc
def

    ghi
    jkl
"""


s3 =
    """
| A
abc
def

| B
ghi
jkl
 """


s4 =
    """
| A
abc
def

    | B
    ghi
    jkl
 """
