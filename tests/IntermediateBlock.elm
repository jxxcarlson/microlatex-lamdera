module IntermediateBlock exposing (..)

import Compiler.Util exposing (depth, size)
import Expect exposing (..)
import Markup
import Parser.Language exposing (Language(..))
import Parser.Line
import Parser.PrimitiveBlock exposing (PrimitiveBlock, blockListOfStringList)
import Test exposing (..)


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
    describe "The intermiediate block parser"
        [ test_ "two paragraphs, no indentation" (ibm s1 |> List.length) 2
        , test_ "two paragraphs, second indented" (ibm s2 |> List.length) 1
        , test_ "two paragraphs, second indented, depth is 1" (ibm s2 |> List.map depth) [ 1 ]
        , test_ "two L1 blocks at indent 0" (ibm s3 |> List.length) 2
        , test_ "two L1 blocks first at indent 0, second at indent 4" (ibm s4 |> List.length) 1
        , test_ "two L1 blocks first at indent 0, second at indent 4, depth is 1" (ibm s4 |> List.map depth) [ 1 ]
        ]


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
