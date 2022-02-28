module MicroLaTeX.Parser.Classify exposing (classify)

import Parser.Block exposing (BlockType(..), ExpressionBlock(..), IntermediateBlock(..))
import Parser.Common
import Tree.BlocksV


classify : Tree.BlocksV.Block -> BlockType
classify block =
    let
        str_ =
            String.trim block.content

        lines =
            String.lines str_

        firstLine =
            List.head lines |> Maybe.withDefault "FIRSTLINE"
    in
    if String.left 5 firstLine == "\\item" then
        OrdinaryBlock [ "item" ]

    else if String.left 9 firstLine == "\\numbered" then
        OrdinaryBlock [ "numbered" ]

    else if String.left 7 firstLine == "\\begin{" then
        let
            name =
                firstLine |> String.replace "\\begin{" "" |> String.replace "}" ""
        in
        if List.member name Parser.Common.verbatimBlockNames then
            VerbatimBlock [ name ]

        else
            OrdinaryBlock [ name ]

    else if String.left 2 str_ == "$$" then
        VerbatimBlock [ "math" ]

    else if String.left 3 str_ == "```" then
        VerbatimBlock [ "code" ]

    else
        Paragraph
