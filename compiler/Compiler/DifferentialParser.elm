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

        includedFiles : List String
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
            case List.head includedFiles of
                Nothing ->
                    chunks

                Just fileName ->
                    prependContent fileName inclusionData chunks

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


prependContent : String -> Dict String String -> List (Tree PrimitiveBlock) -> List (Tree PrimitiveBlock)
prependContent tag dict trees =
    Tree.singleton (makeBlock tag dict) :: trees


makeBlock : String -> Dict String String -> PrimitiveBlock
makeBlock tag dict =
    let
        empty =
            Parser.PrimitiveBlock.empty
    in
    case Dict.get tag dict of
        Nothing ->
            empty

        Just content ->
            { empty
                | blockType = PBVerbatim
                , name = Just "mathmacros"
                , content = String.lines content |> List.drop 1
            }


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
            Tree.map (Parser.BlockUtil.toExpressionBlock lang MicroLaTeX.Parser.Expression.parse)

        L0Lang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock lang L0.Parser.Expression.parse)

        PlainTextLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock lang (\i s -> ( Markup.parsePlainText i s, [] )))

        XMarkdownLang ->
            Tree.map (Parser.BlockUtil.toExpressionBlock lang (\i s -> ( XMarkdown.Expression.parse i s, [] )))
