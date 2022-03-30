module Markup exposing
    ( parse
    , isVerbatimLine, toPrimitiveBlockForest
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
import Parser.Forest exposing (Forest)
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)
import Parser.Tree
import Tree
import XMarkdown.Expression


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

                XMarkdownLang ->
                    -- TODO: implement this
                    XMarkdown.Expression.parse
    in
    sourceText
        |> toPrimitiveBlockForest lang
        |> List.map (Tree.map (Parser.BlockUtil.toExpressionBlock parser))


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
