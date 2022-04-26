module Compiler.DifferentialParser exposing (EditRecord, init, update)

import Compiler.AbstractDifferentialParser as Abstract
import Compiler.Acc
import Dict exposing (Dict)
import L0.Parser.Expression
import List.Extra
import Markup
import MicroLaTeX.Parser.Expression
import Parser.Block exposing (ExpressionBlock)
import Parser.BlockUtil
import Parser.Language exposing (Language(..))
import Parser.Line exposing (PrimitiveBlockType(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)
import Tree exposing (Tree)
import XMarkdown.Expression


type alias EditRecord =
    Abstract.EditRecord (Tree PrimitiveBlock) (Tree ExpressionBlock) Compiler.Acc.Accumulator


init : Dict String String -> Language -> String -> EditRecord
init inclusionData lang str =
    let
        chunks : List (Tree PrimitiveBlock)
        chunks =
            chunker lang str

        includedFiles =
            case List.head chunks of
                Nothing ->
                    []

                Just chunk ->
                    let
                        lines =
                            (Tree.label chunk).content
                    in
                    case List.head lines of
                        Nothing ->
                            []

                        Just "|| load-files" ->
                            List.drop 1 lines

                        _ ->
                            []

        updatedChunks =
            if includedFiles == [] then
                chunks

            else
                includeContent inclusionData chunks

        -- Tree { content } ->
        ( newAccumulator, parsed ) =
            (List.map (parser lang) >> Compiler.Acc.transformAcccumulate lang) updatedChunks
    in
    { lang = lang
    , chunks = chunks
    , parsed = parsed
    , accumulator = newAccumulator
    , messages = Markup.messagesFromForest parsed
    , includedFiles = includedFiles
    }


includeContent : Dict String String -> List (Tree PrimitiveBlock) -> List (Tree PrimitiveBlock)
includeContent dict trees =
    let
        _ =
            Debug.log "!! DICT" dict
    in
    List.map (includeContentForTree dict) trees


includeContentForTree : Dict String String -> Tree PrimitiveBlock -> Tree PrimitiveBlock
includeContentForTree dict tree =
    Tree.map (includeContentForBlock dict) tree


includeContentForBlock : Dict String String -> PrimitiveBlock -> PrimitiveBlock
includeContentForBlock dict block =
    let
        _ =
            Debug.log "!! BLOCK (1)" block
    in
    case block.name of
        Nothing ->
            block

        Just blockName ->
            if blockName /= "include" then
                block

            else
                case List.Extra.getAt 1 block.content of
                    Nothing ->
                        block

                    Just tag ->
                        case Dict.get tag dict of
                            Nothing ->
                                block

                            Just content ->
                                let
                                    _ =
                                        Debug.log "!! BLOCK (2)" content
                                in
                                { block | blockType = PBParagraph, name = Nothing, content = [ content ] } |> Debug.log "!! BLOCK (3)"


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
            Tree.map (Parser.BlockUtil.toExpressionBlock MicroLaTeX.Parser.Expression.parse)

        L0Lang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock L0.Parser.Expression.parse)

        PlainTextLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock (\i s -> ( Markup.parsePlainText i s, [] )))

        XMarkdownLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock (\i s -> ( XMarkdown.Expression.parse i s, [] )))
