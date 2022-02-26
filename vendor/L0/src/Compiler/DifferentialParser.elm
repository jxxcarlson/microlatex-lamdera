module Compiler.DifferentialParser exposing (EditRecord, init, update)

import Compiler.AbstractDifferentialParser as Abstract
import Compiler.Acc
import Compiler.Differ as Differ
import L0
import Parser.Block exposing (ExpressionBlock, IntermediateBlock)
import Parser.BlockUtil
import Parser.Language exposing (Language(..))
import Tree exposing (Tree)


type alias EditRecord =
    Abstract.EditRecord (Tree IntermediateBlock) (Tree ExpressionBlock) Compiler.Acc.Accumulator


init : Language -> String -> EditRecord
init lang str =
    let
        chunks : List (Tree IntermediateBlock)
        chunks =
            chunker str

        ( newAccumulator, parsed ) =
            (List.map parser >> Compiler.Acc.make lang) chunks
    in
    { lang = lang, chunks = chunks, parsed = parsed, accumulator = newAccumulator }


update : EditRecord -> String -> EditRecord
update editRecord text =
    let
        f : Language -> List (Tree IntermediateBlock) -> ( Compiler.Acc.Accumulator, List (Tree ExpressionBlock) )
        f =
            \lang -> List.map parser >> Compiler.Acc.make lang
    in
    Abstract.update chunker parser f editRecord text


differentialParser diffRecord editRecord =
    Abstract.differentialParser chunker diffRecord editRecord


chunker : String -> List (Tree IntermediateBlock)
chunker =
    L0.parseToIntermediateBlocks


parser : Tree IntermediateBlock -> Tree ExpressionBlock
parser =
    Tree.map Parser.BlockUtil.toExpressionBlockFromIntermediateBlock



--renderer =
--    Tree.map (Render.Block.render 0 Settings.defaultSettings)
--differentialParser = differentialParser parser diffRecord editRecord
