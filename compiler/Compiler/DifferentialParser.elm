module Compiler.DifferentialParser exposing (EditRecord, init, update)

import Compiler.AbstractDifferentialParser as Abstract
import Compiler.Acc
import L0.Parser.Expression
import Markup
import MicroLaTeX.Parser.Expression
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
            chunker lang str

        ( newAccumulator, parsed ) =
            (List.map (parser lang) >> Compiler.Acc.make lang) chunks
    in
    { lang = lang, chunks = chunks, parsed = parsed, accumulator = newAccumulator }


update : EditRecord -> String -> EditRecord
update editRecord text =
    Abstract.update (chunker editRecord.lang) (parser editRecord.lang) Compiler.Acc.make editRecord text


chunker : Language -> String -> List (Tree IntermediateBlock)
chunker lang =
    Markup.parseToIntermediateBlocks lang


parser : Language -> Tree IntermediateBlock -> Tree ExpressionBlock
parser lang =
    case lang of
        MicroLaTeXLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlockFromIntermediateBlock MicroLaTeX.Parser.Expression.parse)

        L0Lang ->
            Tree.map (Parser.BlockUtil.toExpressionBlockFromIntermediateBlock L0.Parser.Expression.parse)
