module L0.Parser.Classify exposing (classify)

import Parser.Block exposing (BlockType(..))
import Tree.BlocksV


classify : Tree.BlocksV.Block -> { blockType : BlockType, args : List String, name : Maybe String }
classify block =
    let
        str_ =
            String.trim block.content

        args =
            str_ |> String.lines |> List.head |> Maybe.withDefault "" |> String.words |> List.drop 1

        name =
            List.head args
    in
    if String.left 2 str_ == "||" then
        { blockType = VerbatimBlock args, args = args, name = name }

    else if String.left 1 str_ == "|" then
        { blockType = OrdinaryBlock args, args = args, name = name }

    else if String.left 2 str_ == "$$" then
        { blockType = VerbatimBlock [ "math" ], args = args, name = name }

    else if String.left 3 str_ == "```" then
        { blockType = VerbatimBlock [ "code" ], args = args, name = name }

    else
        { blockType = Paragraph, args = [], name = Nothing }
