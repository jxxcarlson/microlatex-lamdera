module L0.Parser.Classify exposing (classify)

import Parser.Block exposing (BlockType(..))
import Parser.Common exposing (Classification)
import Parser.Line exposing (PrimitiveBlockType(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)


classify : PrimitiveBlock -> Classification
classify block =
    let
        bt =
            case block.blockType of
                PBParagraph ->
                    Paragraph

                PBOrdinary ->
                    OrdinaryBlock args

                PBVerbatim ->
                    VerbatimBlock args

        args =
            block.args

        name =
            block.name
    in
    { blockType = bt, args = args, name = name }
