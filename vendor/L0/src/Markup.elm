module Markup exposing (SyntaxTree, parse, parseToIntermediateBlocks)

{-| A Parser for the experimental Markup module. See the app folder to see how it is used.
The Render folder in app could have been included with the parser. However, this way
users are free to design their own renderer.

Since this package is still experimental (but needed in various test projects).
The documentation is skimpy.

@docs SyntaxTree, parse, parseToIntermediateBlocks

-}

import L0.Parser.Classify
import L0.Parser.Expression
import MicroLaTeX.Parser.Classify
import MicroLaTeX.Parser.Expression
import Parser.Block
import Parser.BlockUtil
import Parser.Expr exposing (Expr)
import Parser.Language exposing (Language(..))
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


parse : Language -> String -> List (Tree (Parser.Block.ExpressionBlock Expr))
parse lang sourceText =
    let
        parser =
            case lang of
                MicroLaTeXLang ->
                    MicroLaTeX.Parser.Expression.parse

                L0Lang ->
                    L0.Parser.Expression.parse
    in
    sourceText
        |> parseToIntermediateBlocks lang
        |> List.map (Tree.map (Parser.BlockUtil.toExpressionBlockFromIntermediateBlock parser))


{-| -}
parseToIntermediateBlocks : Language -> String -> List (Tree Parser.Block.IntermediateBlock)
parseToIntermediateBlocks lang sourceText =
    let
        toIntermediateBlock =
            case lang of
                MicroLaTeXLang ->
                    Parser.BlockUtil.toIntermediateBlock MicroLaTeX.Parser.Classify.classify MicroLaTeX.Parser.Expression.parseToState MicroLaTeX.Parser.Expression.extractMessages

                L0Lang ->
                    Parser.BlockUtil.toIntermediateBlock L0.Parser.Classify.classify L0.Parser.Expression.parseToState L0.Parser.Expression.extractMessages
    in
    sourceText
        |> Tree.BlocksV.fromStringAsParagraphs isVerbatimLine
        |> Tree.Build.forestFromBlocks Parser.BlockUtil.empty
            toIntermediateBlock
            Parser.BlockUtil.toBlockFromIntermediateBlock
        |> Result.withDefault []
