module MicroLaTeX.Parser.Classify exposing (classify)

import Parser.Block exposing (BlockType(..), RawBlock)
import Parser.Common


classify : RawBlock -> { blockType : BlockType, args : List String }
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
        { blockType = OrdinaryBlock [ "item" ], args = [] }

    else if String.left 6 firstLine == "\\index" then
        { blockType = OrdinaryBlock [ "index" ], args = [] }

    else if String.left 9 firstLine == "\\abstract" then
        { blockType = OrdinaryBlock [ "abstract" ], args = [] }

    else if String.left 9 firstLine == "\\numbered" then
        { blockType = OrdinaryBlock [ "numbered" ], args = [] }
        --else if String.left 11 firstLine == "\\setcounter" then
        --    { blockType = OrdinaryBlock [ "setcounter" ], args = [] }

    else if String.left 5 firstLine == "\\desc" then
        let
            args =
                String.replace "\\desc" "" firstLine |> String.words
        in
        { blockType = OrdinaryBlock [ "desc" ], args = args }

    else if String.left 7 firstLine == "\\begin{" then
        let
            name =
                firstLine |> String.replace "\\begin{" "" |> String.replace "}" ""
        in
        if List.member name Parser.Common.verbatimBlockNames then
            { blockType = VerbatimBlock [ name ], args = [] }

        else
            { blockType = OrdinaryBlock [ name ], args = [] }

    else if String.left 2 str_ == "$$" then
        { blockType = VerbatimBlock [ "math" ], args = [] }

    else if String.left 3 str_ == "```" then
        { blockType = VerbatimBlock [ "code" ], args = [] }

    else
        { blockType = Paragraph, args = [] }
