module Markup exposing (SyntaxTree, parse, parseToIntermediateBlocks)

{-| A Parser for the experimental Markup module. See the app folder to see how it is used.
The Render folder in app could have been included with the parser. However, this way
users are free to design their own renderer.

Since this package is still experimental (but needed in various test projects).
The documentation is skimpy.

@docs SyntaxTree, parse, parseToIntermediateBlocks

-}

import MicroLaTeX.Parser.Classify
import MicroLaTeX.Parser.Expression
import Parser.Block
import Parser.BlockUtil
import Parser.Expr exposing (Expr)
import Tree exposing (Tree)
import Tree.BlocksV
import Tree.Build exposing (Error)


{-| -}
type alias SyntaxTree =
    List (Tree (Parser.Block.ExpressionBlock Expr))


isVerbatimLine : String -> Bool
isVerbatimLine str =
    String.left 2 str == "||"


{-| -}



-- parse : String -> SyntaxTree
-- parse : String -> List (Tree Parser.Block.IntermediateBlock)


parse : String -> List (Tree (Parser.Block.ExpressionBlock Expr))
parse sourceText =
    sourceText
        |> parseToIntermediateBlocks
        |> List.map (Tree.map (Parser.BlockUtil.toExpressionBlockFromIntermediateBlock MicroLaTeX.Parser.Expression.parse))


{-| -}
parseToIntermediateBlocks : String -> List (Tree Parser.Block.IntermediateBlock)
parseToIntermediateBlocks sourceText =
    sourceText
        |> Tree.BlocksV.fromStringAsParagraphs isVerbatimLine
        |> Tree.Build.forestFromBlocks Parser.BlockUtil.empty
            (Parser.BlockUtil.toIntermediateBlock MicroLaTeX.Parser.Classify.classify MicroLaTeX.Parser.Expression.parseToState MicroLaTeX.Parser.Expression.extractMessages)
            Parser.BlockUtil.toBlockFromIntermediateBlock
        |> Result.withDefault []



-- |> Tree.Build.forestFromBlocks Parser.BlockUtil.l0Empty Parser.BlockUtil.toExpressionBlock Parser.BlockUtil.toBlock
--b =
--    Tree.BlocksV.fromStringAsParagraphs isVerbatimLine
--
--
--bb =
--    Tree.BlocksV.fromStringAsParagraphs isVerbatimLine >> Tree.Build.forestFromBlocks Parser.BlockUtil.l0Empty Parser.BlockUtil.toExpressionBlock Parser.BlockUtil.toBlock
