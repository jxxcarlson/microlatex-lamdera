module Markup exposing
    ( parse
    , example1a, example1b, example2, example3, f, g, h, isVerbatimLine, messagesFromForest, parsePlainText, toPrimitiveBlockForest, x1, x2
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


example2 =
    """
| theorem

  $$
  x^2

  $$
  y^2


   """


example3 =
    """
| theorem

  $$
  x^2
  $$

  $$
  y^2
  $$
"""



--> Markup.parse MicroLaTeXLang example3
--[
--  Tree (ExpressionBlock { args = [], blockType = OrdinaryBlock [], content = Right [], id = "2", indent = 0, lineNumber = 2, messages = [], name = Just "theorem", numberOfLines = 1, sourceText = "| theorem", tag = "" })
--    [  Tree (ExpressionBlock { args = [], blockType = VerbatimBlock [], content = Left "x^2", id = "4", indent = 2, lineNumber = 4, messages = [], name = Just "math", numberOfLines = 2, sourceText = "$$\nx^2", tag = "" }) []
--     , Tree (ExpressionBlock { args = [], blockType = VerbatimBlock [], content = Left "y^2", id = "8", indent = 2, lineNumber = 8, messages = [], name = Just "math", numberOfLines = 2, sourceText = "$$\ny^2", tag = "" }) []
--    ]
--]
--
--> Markup.parse MicroLaTeXLang example2
--[
--  Tree (ExpressionBlock { args = [], blockType = OrdinaryBlock [], content = Right [], id = "2", indent = 0, lineNumber = 2, messages = [], name = Just "theorem", numberOfLines = 1, sourceText = "| theorem", tag = "" })
--    [  Tree (ExpressionBlock { args = [], blockType = VerbatimBlock [], content = Left "x^2", id = "4", indent = 2, lineNumber = 4, messages = [], name = Just "math", numberOfLines = 2, sourceText = "$$\nx^2", tag = "" }) []
--      ,Tree (ExpressionBlock { args = [], blockType = Paragraph, content = Right [Text ("   y^2") { begin = 0, end = 4, id = "0.4", index = 0 }], id = "8", indent = 2, lineNumber = 8, messages = [], name = Nothing, numberOfLines = 1, sourceText = "  y^2", tag = "" }) []]]


example1a =
    """
\\cslink{Tips jxxcarlson:tips}

"""


example1b =
    """
[cslink Tips jxxcarlson:tips]

"""



--[
--  Tree (ExpressionBlock { args = [], blockType = OrdinaryBlock [], content = Right [Text "AAA" { begin = 0, end = 2, id = "0.0", index = 0 }], id = "2", indent = 0, lineNumber = 2, messages = [], name = Just "item", numberOfLines = 2, sourceText = "| item\nAAA", tag = "" }) []
-- ,Tree (ExpressionBlock { args = [], blockType = OrdinaryBlock [], content = Right [Text "BBB" { begin = 0, end = 2, id = "0.0", index = 0 }], id = "5", indent = 0, lineNumber = 5, messages = [], name = Just "tem", numberOfLines = 2, sourceText = "|item\nBBB", tag = "" }) []
-- ,Tree (ExpressionBlock { args = [], blockType = OrdinaryBlock [], content = Right [Text "CCC" { begin = 0, end = 2, id = "0.0", index = 0 }], id = "8", indent = 0, lineNumber = 8, messages = [], name = Just "item", numberOfLines = 2, sourceText = "| item\nCCC", tag = "" }) []]


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
                    \_ s -> ( parsePlainText s, [] )

                XMarkdownLang ->
                    \i s -> ( XMarkdown.Expression.parse i s, [] )
    in
    sourceText
        |> toPrimitiveBlockForest lang
        |> Parser.Forest.map (Parser.BlockUtil.toExpressionBlock lang parser)


messagesFromTree : Tree.Tree ExpressionBlock -> List String
messagesFromTree tree =
    List.map Parser.BlockUtil.getMessages (Tree.flatten tree) |> List.concat


messagesFromForest : Forest ExpressionBlock -> List String
messagesFromForest forest =
    List.map messagesFromTree forest |> List.concat


parsePlainText : String -> List Parser.Expr.Expr
parsePlainText str =
    [ Text str { begin = 0, end = 0, index = 0, id = "??" } ]


emptyBlock =
    Parser.PrimitiveBlock.empty


toPrimitiveBlockForest : Language -> String -> Forest PrimitiveBlock
toPrimitiveBlockForest lang str =
    str
        |> String.lines
        |> Parser.PrimitiveBlock.parse lang isVerbatimLine
        |> List.map (Compiler.Transform.transform lang)
        |> Parser.Tree.forestFromBlocks { emptyBlock | indent = -2 } identity identity
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
