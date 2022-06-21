module Markup exposing
    ( parse
    , example, f, g, h, isVerbatimLine, messagesFromForest, parsePlainText, toPrimitiveBlockForest, x1, x2
    )

{-| A Parser for the experimental Markup module. See the app folder to see how it is used.
The Render folder in app could have been included with the parser. However, this way
users are free to design their own renderer.

Since this package is still experimental (but needed in various test projects).
The documentation is skimpy.

@docs parse, parseToIntermediateBlocks

-}

import Compiler.Transform
import L0.Parser.Expression
import MicroLaTeX.Parser.Expression
import Parser.Block exposing (ExpressionBlock)
import Parser.BlockUtil
import Parser.Expr exposing (Expr(..))
import Parser.Forest exposing (Forest)
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)
import Parser.Tree
import Tree
import XMarkdown.Expression


example =
    """
\\begin{theorem}
This is a test.

  \\begin{equation}
  a^2 + b^2 = c^3

  Isn't that nice?
"""



-- [
--   { args = [], blockType = PBOrdinary, content = ["| title","L0 Test"], indent = 0, lineNumber = 1, name = Just "title", named = True, position = 0, sourceText = "| title\nL0 Test" }
--  ,{ args = [], blockType = PBOrdinary, content = ["| indent","AAA"], indent = 0, lineNumber = 4, name = Just "indent", named = True, position = 14, sourceText = "| indent\nAAA" }
--  ,{ args = [], blockType = PBOrdinary, content = ["  | indent ","BBB"], indent = 2, lineNumber = 7, name = Just "indent", named = True, position = 25, sourceText = "  | indent \nBBB" }
--  ,{ args = [], blockType = PBOrdinary, content = ["    | indent","CCC"], indent = 4, lineNumber = 10, name = Just "indent", named = True, position = 37, sourceText = "    | indent\nCCC" }
--]
--
--!! FOREST (0): Ok
--[
--   Tree { args = [], blockType = PBOrdinary, content = ["| title","L0 Test"], indent = 0, lineNumber = 1, name = Just "title", named = True, position = 0, sourceText = "| title\nL0 Test" } []
--  ,Tree { args = [], blockType = PBOrdinary, content = ["| indent","AAA"], indent = 0, lineNumber = 4, name = Just "indent", named = True, position = 14, sourceText = "| indent\nAAA" }
--    [Tree { args = [], blockType = PBOrdinary, content = ["  | indent ","BBB"], indent = 2, lineNumber = 7, name = Just "indent", named = True, position = 25, sourceText = "  | indent \nBBB" }
--      [Tree { args = [], blockType = PBOrdinary, content = ["    | indent","CCC"], indent = 4, lineNumber = 10, name = Just "indent", named = True, position = 37, sourceText = "    | indent\nCCC" }
--        []
--      ]
--    ]
--  ]
--FOREST!!!:
--[
--  Tree "" []
-- ,Tree "\\begin{indent}\nAAA\n\\end{indent}"
--    [Tree "\\begin{indent}\nBBB\n\\end{indent}"
--       [Tree "\\begin{indent}\nCCC\n\\end{indent}"
--          []
--       ]
--    ]
-- ]
--FOREST!!!:
--[
--   Tree "" []
--  ,Tree "\\begin{theorem}\nAlso a test.\n\\end{theorem}"
--     [
--        Tree "\\begin{theorem}\nFoo, bar!\n\\end{theorem}" [],
--        Tree "   Isn't that nice?" []
--     ]
--]
--
--[
--  Tree { args = ["MicroLaTeX  Test"], blockType = PBOrdinary, content = ["| title","MicroLaTeX  Test"], indent = 0, lineNumber = 1, name = Just "title", named = True, position = 0, sourceText = "\\title{MicroLaTeX Test}" }
--    []
-- ,Tree { args = [], blockType = PBOrdinary, content = ["| theorem","This is a test."], indent = 0, lineNumber = 4, name = Just "theorem", named = True, position = 24, sourceText = "| theorem\nThis is a test." }
--    []
-- ,Tree { args = [], blockType = PBVerbatim, content = ["|| equation","  a^2 + b^2 = c^3"], indent = 0, lineNumber = 7, name = Just "equation", named = True, position = 48, sourceText = "|| equation\n  a^2 + b^2 = c^3" }
--   [Tree { args = [], blockType = PBParagraph, content = ["  Isn't that nice?"], indent = 2, lineNumber = 10, name = Nothing, named = True, position = 74, sourceText = "  Isn't that nice?" }
--     []
--   ]
--]
--[
--   Tree { args = ["MicroLaTeX  Test"], blockType = PBOrdinary, content = ["| title","MicroLaTeX  Test"], indent = 0, lineNumber = 1, name = Just "title", named = True, position = 0, sourceText = "\\title{MicroLaTeX Test}" }
--     []
--  ,Tree { args = [], blockType = PBOrdinary, content = ["| theorem","This is a test."], indent = 0, lineNumber = 4, name = Just "theorem", named = True, position = 24, sourceText = "| theorem\nThis is a test." }
--     []
--  ,Tree { args = [], blockType = PBVerbatim, content = ["|| equation","  a^2 + b^2 = c^3"], indent = 0, lineNumber = 7, name = Just "equation", named = True, position = 48, sourceText = "|| equation\n  a^2 + b^2 = c^3" }
--     [Tree { args = [], blockType = PBParagraph, content = [" Isn't that nice?"], indent = 1, lineNumber = 10, name = Nothing, named = True, position = 74, sourceText = " Isn't that nice?" }
--       []]
--]
-- f = [Tree { args = ["MicroLaTeX  Test"], blockType = PBOrdinary, content = ["| title","MicroLaTeX  Test"], indent = 0, lineNumber = 1, name = Just "title", named = True, position = 0, sourceText = "\\title{MicroLaTeX Test}" } [],Tree { args = [], blockType = PBOrdinary, content = ["| theorem","This is a test."], indent = 0, lineNumber = 4, name = Just "theorem", named = True, position = 24, sourceText = "| theorem\nThis is a test." } [],Tree { args = [], blockType = PBVerbatim, content = ["|| equation","    a^2 + b^2 = c^2","    "], indent = 0, lineNumber = 7, name = Just "equation", named = True, position = 48, sourceText = "|| equation\n    a^2 + b^2 = c^2\n    " } [Tree { args = [], blockType = PBParagraph, content = ["    Isn't that nice?"], indent = 4, lineNumber = 11, name = Nothing, named = True, position = 74, sourceText = "    Isn't that nice?" } []]]


{-| -}
parse : Language -> String -> Forest ExpressionBlock
parse lang sourceText =
    let
        parser =
            case lang of
                MicroLaTeXLang ->
                    MicroLaTeX.Parser.Expression.parse

                L0Lang ->
                    L0.Parser.Expression.parse

                PlainTextLang ->
                    \i s -> ( parsePlainText i s, [] )

                XMarkdownLang ->
                    \i s -> ( XMarkdown.Expression.parse i s, [] )
    in
    sourceText
        |> toPrimitiveBlockForest lang
        |> Debug.log "!! PrimitiveBlockForest"
        |> Parser.Forest.map (Parser.BlockUtil.toExpressionBlock lang parser)


messagesFromTree : Tree.Tree ExpressionBlock -> List String
messagesFromTree tree =
    List.map Parser.BlockUtil.getMessages (Tree.flatten tree) |> List.concat


messagesFromForest : Forest ExpressionBlock -> List String
messagesFromForest forest =
    List.map messagesFromTree forest |> List.concat


parsePlainText : Int -> String -> List Parser.Expr.Expr
parsePlainText lineNumber str =
    [ Text str { begin = 0, end = 0, index = 0, id = "??" } ]


emptyBlock =
    Parser.PrimitiveBlock.empty


toPrimitiveBlockForest : Language -> String -> Forest PrimitiveBlock
toPrimitiveBlockForest lang str =
    str
        |> String.lines
        |> Parser.PrimitiveBlock.parse lang isVerbatimLine
        |> Debug.log "!! PRIMITIVE BLOCKS (1)"
        |> List.map (Compiler.Transform.transform lang)
        |> Debug.log "!! PRIMITIVE BLOCKS (2)"
        |> Parser.Tree.forestFromBlocks { emptyBlock | indent = -2 } identity identity
        |> Debug.log "!! FOREST (0)"
        |> Result.withDefault []


isVerbatimLine : String -> Bool
isVerbatimLine str =
    (String.left 2 str == "||")
        || (String.left 3 str == "```")
        || (String.left 16 str == "\\begin{equation}")
        || (String.left 15 str == "\\begin{aligned}")
        || (String.left 15 str == "\\begin{comment}")
        || (String.left 12 str == "\\begin{code}")
        || (String.left 12 str == "\\begin{verbatim}")
        || (String.left 18 str == "\\begin{mathmacros}")
        || (String.left 2 str == "$$")


f str =
    parse L0Lang str


g str =
    parse MicroLaTeXLang str


h str =
    toPrimitiveBlockForest XMarkdownLang str


x1 =
    """
```
# multiplication table
  for x in range(1, 11):
      for y in range(1, 11):
          print('%d * %d = %d' % (x, y, x*y))
```
"""


x2 =
    """
|| code
# multiplication table
  for x in range(1, 11):
      for y in range(1, 11):
          print('%d * %d = %d' % (x, y, x*y))
"""
