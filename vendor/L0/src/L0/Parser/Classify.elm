module L0.Parser.Classify exposing (..)

import Parser.Block exposing (BlockType(..), ExpressionBlock(..), IntermediateBlock(..))
import Tree.BlocksV


classify : Tree.BlocksV.Block -> BlockType
classify block =
    let
        str_ =
            String.trim block.content
    in
    if String.left 2 str_ == "||" then
        VerbatimBlock (str_ |> String.lines |> List.head |> Maybe.withDefault "" |> String.words |> List.drop 1)

    else if String.left 1 str_ == "|" then
        OrdinaryBlock (str_ |> String.lines |> List.head |> Maybe.withDefault "" |> String.words |> List.drop 1)

    else if String.left 2 str_ == "$$" then
        VerbatimBlock [ "math" ]

    else if String.left 3 str_ == "```" then
        VerbatimBlock [ "code" ]

    else
        Paragraph
