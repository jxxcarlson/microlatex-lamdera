module Markup exposing
    ( SyntaxTree, parse, parseToIntermediateBlocks
    , toRawBlockForest, toRawBlocks
    )

{-| A Parser for the experimental Markup module. See the app folder to see how it is used.
The Render folder in app could have been included with the parser. However, this way
users are free to design their own renderer.

Since this package is still experimental (but needed in various test projects).
The documentation is skimpy.

@docs SyntaxTree, parse, parseToIntermediateBlocks

-}

import L0.Parser.Expression
import MicroLaTeX.Parser.Expression
import Parser.Block exposing (ExpressionBlock, IntermediateBlock(..), RawBlock)
import Parser.BlockUtil
import Parser.Language exposing (Language(..))
import Tree exposing (Tree)
import Tree.BlocksV
import Tree.Build


{-| -}
type alias SyntaxTree =
    List (Tree ExpressionBlock)


isVerbatimLine : String -> Bool
isVerbatimLine str =
    (String.left 2 str == "||")
        || (String.left 16 str == "\\begin{equation}")
        || (String.left 15 str == "\\begin{aligned}")
        || (String.left 15 str == "\\begin{comment}")
        || (String.left 12 str == "\\begin{code}")
        || (String.left 18 str == "\\begin{mathmacros}")
        || (String.left 2 str == "$$")


{-| -}
parse : Language -> String -> List (Tree ExpressionBlock)
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
        |> Debug.log "INTERMEDIATE"
        |> List.map (Tree.map (Parser.BlockUtil.toExpressionBlockFromIntermediateBlock parser))


parseToIntermediateBlocks : Language -> String -> List (Tree IntermediateBlock)
parseToIntermediateBlocks lang sourceText =
    let
        toIntermediateBlock : RawBlock -> IntermediateBlock
        toIntermediateBlock =
            case lang of
                MicroLaTeXLang ->
                    Parser.BlockUtil.toIntermediateBlock lang MicroLaTeX.Parser.Expression.parseToState MicroLaTeX.Parser.Expression.extractMessages

                L0Lang ->
                    Parser.BlockUtil.toIntermediateBlock lang L0.Parser.Expression.parseToState L0.Parser.Expression.extractMessages
    in
    sourceText
        |> toRawBlockForest
        |> List.map (Tree.map toIntermediateBlock >> fixup)


{-| The purpose of this function is to supress error messages in the case
of ordinary blocks that are the root of a nontrivial tree. Not a great
solution -- need to find something better.
-}
fixup : Tree IntermediateBlock -> Tree IntermediateBlock
fixup tree =
    let
        numberOfChildren =
            List.length (Tree.children tree)

        fixContent : IntermediateBlock -> IntermediateBlock
        fixContent (Parser.Block.IntermediateBlock data) =
            let
                badString =
                    "\n•••\\vskip{1}\n\\red{\\bs{end} •••}"

                newContent =
                    String.replace badString " " data.content
            in
            IntermediateBlock { data | content = newContent }
    in
    if numberOfChildren == 0 then
        tree

    else
        Tree.mapLabel fixContent tree


toRawBlocks : String -> List RawBlock
toRawBlocks =
    Tree.BlocksV.fromStringAsParagraphs isVerbatimLine


toRawBlockForest : String -> List (Tree RawBlock)
toRawBlockForest str =
    str
        |> toRawBlocks
        |> Tree.Build.forestFromBlocks emptyBlock identity identity
        |> Result.withDefault []


emptyBlock =
    { content = "", indent = 0, lineNumber = 0, numberOfLines = 1 }
