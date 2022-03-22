module Compiler.DifferentialParser exposing (EditRecord, init, update)

import Compiler.AbstractDifferentialParser as Abstract
import Compiler.Acc
import L0.Parser.Expression
import Markup
import MicroLaTeX.Parser.Expression
import Parser.Block exposing (ExpressionBlock)
import Parser.BlockUtil
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)
import Tree exposing (Tree)


type alias EditRecord =
    Abstract.EditRecord (Tree PrimitiveBlock) (Tree ExpressionBlock) Compiler.Acc.Accumulator


init : Language -> String -> EditRecord
init lang str =
    let
        chunks : List (Tree PrimitiveBlock)
        chunks =
            chunker lang str

        ( newAccumulator, parsed ) =
            (List.map (parser lang) >> Compiler.Acc.transformAcccumulate lang) chunks
    in
    { lang = lang, chunks = chunks, parsed = parsed, accumulator = newAccumulator }


update : EditRecord -> String -> EditRecord
update editRecord text =
    Abstract.update (chunker editRecord.lang) (parser editRecord.lang) Compiler.Acc.transformAcccumulate editRecord text


chunker : Language -> String -> List (Tree PrimitiveBlock)
chunker lang =
    Markup.toPrimitiveBlockForest lang


parser : Language -> Tree PrimitiveBlock -> Tree ExpressionBlock
parser lang =
    case lang of
        MicroLaTeXLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock MicroLaTeX.Parser.Expression.parse)

        L0Lang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock L0.Parser.Expression.parse)

        XMarkdownLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock L0.Parser.Expression.parse)
