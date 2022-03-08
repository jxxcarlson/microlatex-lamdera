module MicroLaTeX.Parser.Classify exposing (Classification, classify)

import Parser.Block exposing (BlockType(..), RawBlock)
import Parser.Common


type alias Classification =
    { blockType : BlockType, args : List String, name : Maybe String }


classify : RawBlock -> Classification
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
        { blockType = OrdinaryBlock [ "item" ], args = [], name = Just "item" }

    else if String.left 6 firstLine == "\\index" then
        { blockType = OrdinaryBlock [ "index" ], args = [], name = Just "index" }

    else if String.left 9 firstLine == "\\abstract" then
        { blockType = OrdinaryBlock [ "abstract" ], args = [], name = Just "abstract" }

    else if String.left 9 firstLine == "\\numbered" then
        { blockType = OrdinaryBlock [ "numbered" ], args = [], name = Just "numbered" }

    else if String.left 5 firstLine == "\\desc" then
        let
            args =
                String.replace "\\desc" "" firstLine |> String.words
        in
        { blockType = OrdinaryBlock [ "desc" ], args = args, name = Just "desc" }

    else if String.left 7 firstLine == "\\begin{" then
        let
            name =
                firstLine |> String.replace "\\begin{" "" |> String.replace "}" ""
        in
        if List.member name Parser.Common.verbatimBlockNames then
            { blockType = VerbatimBlock [ name ], args = [], name = Just name }

        else
            { blockType = OrdinaryBlock [ name ], args = [], name = Just name }

    else if String.left 2 str_ == "$$" then
        { blockType = VerbatimBlock [ "math" ], args = [], name = Just "math" }

    else if String.left 3 str_ == "```" then
        { blockType = VerbatimBlock [ "code" ], args = [], name = Just "code" }

    else
        { blockType = Paragraph, args = [], name = Nothing }
