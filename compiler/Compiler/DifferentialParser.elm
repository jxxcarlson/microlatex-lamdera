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
import XMarkdown.Expression


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
    { lang = lang, chunks = chunks, parsed = parsed, accumulator = newAccumulator, messages = Markup.messagesFromForest parsed |> Debug.log "MESSAGES (2)" }


update : EditRecord -> String -> EditRecord
update editRecord text =
    Abstract.update (chunker editRecord.lang) (parser editRecord.lang) Markup.messagesFromForest Compiler.Acc.transformAcccumulate editRecord text


chunker : Language -> String -> List (Tree PrimitiveBlock)
chunker lang =
    Markup.toPrimitiveBlockForest lang


parser : Language -> Tree PrimitiveBlock -> Tree ExpressionBlock
parser lang =
    case lang of
        MicroLaTeXLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock (\i s -> ( MicroLaTeX.Parser.Expression.parse i s, [] )))

        L0Lang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock L0.Parser.Expression.parse)

        PlainTextLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock (\i s -> ( Markup.parsePlainText i s, [] )))

        XMarkdownLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock (\i s -> ( XMarkdown.Expression.parse i s, [] )))
