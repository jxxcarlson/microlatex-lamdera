module PrimitiveBlock exposing (suite, suiteL0, suiteMicroLaTeX, suiteXMarkdown)

import Compiler.Transform
import Expect exposing (..)
import Markup
import Parser.Language exposing (Language(..))
import Parser.Line exposing (PrimitiveBlockType(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock, parse)
import Test exposing (..)


bll str =
    parse L0Lang Markup.isVerbatimLine (String.lines str)


bllc str =
    parse L0Lang Markup.isVerbatimLine (String.lines str) |> List.map .content


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


toPrimitiveBlocks : Language -> String -> List PrimitiveBlock
toPrimitiveBlocks lang str =
    str
        |> String.lines
        |> Parser.PrimitiveBlock.parse lang Markup.isVerbatimLine
        |> List.map (Compiler.Transform.transform lang)



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


suiteL0 : Test
suiteL0 =
    describe "parsing primitive blocks for L0"
        [ test_ "paragraphs" (toPrimitiveBlocks L0Lang "abc\ndef\n\nghi\njkl") [ { args = [], blockType = PBParagraph, content = [ "abc", "def" ], indent = 0, lineNumber = 1, name = Nothing, named = True, position = 0, sourceText = "abc\ndef" }, { args = [], blockType = PBParagraph, content = [ "ghi", "jkl" ], indent = 0, lineNumber = 4, name = Nothing, named = True, position = 6, sourceText = "ghi\njkl" } ]
        , test_ "ordinary block" (toPrimitiveBlocks L0Lang "| theorem\nabc\ndef\n\n") [ { args = [], blockType = PBOrdinary, content = [ "| theorem", "abc", "def" ], indent = 0, lineNumber = 1, name = Just "theorem", named = True, position = 0, sourceText = "| theorem\nabc\ndef" } ]
        , test_ "code block" (toPrimitiveBlocks L0Lang "|| code\nabc\ndef\n\n") [ { args = [], blockType = PBVerbatim, content = [ "|| code", "abc", "def" ], indent = 0, lineNumber = 1, name = Just "code", named = True, position = 0, sourceText = "|| code\nabc\ndef" } ]
        , test_ "item block" (toPrimitiveBlocks L0Lang "| item\nho ho ho!\n\n") [ { args = [], blockType = PBOrdinary, content = [ "| item", "ho ho ho!" ], indent = 0, lineNumber = 1, name = Just "item", named = True, position = 0, sourceText = "| item\nho ho ho!" } ]
        , test_ "math block" (toPrimitiveBlocks L0Lang "$$\nx^2\n\n") [ { args = [], blockType = PBVerbatim, content = [ "$$", "x^2" ], indent = 0, lineNumber = 1, name = Just "math", named = True, position = 0, sourceText = "$$\nx^2" } ]
        ]


suiteMicroLaTeX : Test
suiteMicroLaTeX =
    describe "parsing primitive blocks for MicroLaTeX"
        [ test_ "paragraphs" (toPrimitiveBlocks MicroLaTeXLang "abc\ndef\n\nghi\njkl") [ { args = [], blockType = PBParagraph, content = [ "abc", "def" ], indent = 0, lineNumber = 1, name = Nothing, named = True, position = 0, sourceText = "abc\ndef" }, { args = [], blockType = PBParagraph, content = [ "ghi", "jkl" ], indent = 0, lineNumber = 4, name = Nothing, named = True, position = 6, sourceText = "ghi\njkl" } ]
        , test_ "theorem block" (toPrimitiveBlocks MicroLaTeXLang "\\begin{theorem}\nabc\ndef\n\\end{theorem}\n") [ { args = [], blockType = PBOrdinary, content = [ "| theorem", "abc", "def" ], indent = 0, lineNumber = 1, name = Just "theorem", named = True, position = 0, sourceText = "| theorem\nabc\ndef" } ]
        , test_ "code block" (toPrimitiveBlocks MicroLaTeXLang codeBlock) [ { args = [], blockType = PBVerbatim, content = [ "|| code", "# Multiplication table", "for x in range(1, 11):", "    for y in range(1, 11):", "        print('%d * %d = %d' % (x, y, x*y))" ], indent = 0, lineNumber = 1, name = Just "code", named = True, position = 0, sourceText = "|| code\n# Multiplication table\nfor x in range(1, 11):\n    for y in range(1, 11):\n        print('%d * %d = %d' % (x, y, x*y))" } ]
        , test_ "item block" (toPrimitiveBlocks MicroLaTeXLang "\\item\nho ho ho!\n\n") [ { args = [], blockType = PBOrdinary, content = [ "| item", "ho ho ho!" ], indent = 0, lineNumber = 1, name = Just "item", named = True, position = 0, sourceText = "| item\nho ho ho!" } ]
        , test_ "math block" (toPrimitiveBlocks L0Lang "$$\nx^2$$\n\n") [ { args = [], blockType = PBVerbatim, content = [ "$$", "x^2$$" ], indent = 0, lineNumber = 1, name = Just "math", named = True, position = 0, sourceText = "$$\nx^2$$" } ]
        ]


suiteXMarkdown : Test
suiteXMarkdown =
    describe "parsing primitive blocks for XMarkdown"
        [ test_ "paragraphs" (toPrimitiveBlocks XMarkdownLang "abc\ndef\n\nghi\njkl") [ { args = [], blockType = PBParagraph, content = [ "abc", "def" ], indent = 0, lineNumber = 1, name = Nothing, named = True, position = 0, sourceText = "abc\ndef" }, { args = [], blockType = PBParagraph, content = [ "ghi", "jkl" ], indent = 0, lineNumber = 4, name = Nothing, named = True, position = 6, sourceText = "ghi\njkl" } ]
        , test_ "section" (toPrimitiveBlocks XMarkdownLang "# Intro\n") [ { args = [ "1" ], blockType = PBOrdinary, content = [ "| section 1", "Intro" ], indent = 0, lineNumber = 1, name = Just "section", named = True, position = 0, sourceText = "# Intro" } ]
        , test_ "code, L0 style" (toPrimitiveBlocks XMarkdownLang codeBlock2) [ { args = [], blockType = PBVerbatim, content = [ "```", "# Multiplication table", "for x in range(1, 11):", "    for y in range(1, 11):", "        print('%d * %d = %d' % (x, y, x*y))" ], indent = 0, lineNumber = 1, name = Just "code", named = True, position = 0, sourceText = "```\n# Multiplication table\nfor x in range(1, 11):\n    for y in range(1, 11):\n        print('%d * %d = %d' % (x, y, x*y))\n```" } ]
        , test_ "item block" (toPrimitiveBlocks XMarkdownLang itemBlock) [ { args = [], blockType = PBOrdinary, content = [ "| item", "One" ], indent = 0, lineNumber = 2, name = Just "item", named = True, position = 1, sourceText = "- One" }, { args = [], blockType = PBOrdinary, content = [ "| item", "Two" ], indent = 0, lineNumber = 4, name = Just "item", named = True, position = 6, sourceText = "- Two" } ]
        , test_ "numbered block" (toPrimitiveBlocks XMarkdownLang numberedBlock) [ { args = [], blockType = PBOrdinary, content = [ "| numbered", "One" ], indent = 0, lineNumber = 2, name = Just "numbered", named = True, position = 1, sourceText = ". One" }, { args = [], blockType = PBOrdinary, content = [ "| numbered", "Two" ], indent = 0, lineNumber = 4, name = Just "numbered", named = True, position = 6, sourceText = ". Two" } ]
        , test_ "math block" (toPrimitiveBlocks XMarkdownLang "$$\nx^2$$\n\n") [ { args = [], blockType = PBVerbatim, content = [ "$$", "x^2$$" ], indent = 0, lineNumber = 1, name = Just "math", named = True, position = 0, sourceText = "$$\nx^2$$" } ]
        ]


itemBlock =
    """
- One

- Two
"""


numberedBlock =
    """
. One

. Two
"""


codeBlock =
    """\\begin{code}
# Multiplication table
for x in range(1, 11):
    for y in range(1, 11):
        print('%d * %d = %d' % (x, y, x*y))
\\end{code}
"""


codeBlock2 =
    """```
# Multiplication table
for x in range(1, 11):
    for y in range(1, 11):
        print('%d * %d = %d' % (x, y, x*y))
```
"""


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
