module Compiler.AbstractDifferentialParser exposing (EditRecord, differentialParser, init, update)

import Compiler.Acc exposing (Accumulator)
import Compiler.Differ as Differ
import Parser.Block exposing (ExpressionBlock)
import Parser.Language exposing (Language(..))
import Tree exposing (Tree)


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Language
    }


init :
    Language
    -> (String -> List chunk)
    -> (Language -> List chunk -> ( acc, List parsedChunk ))
    -> String
    -> EditRecord chunk parsedChunk acc
init lang chunker accMaker text =
    let
        chunks =
            chunker text

        ( newAccumulator, parsed ) =
            accMaker lang chunks
    in
    { lang = lang, chunks = chunks, parsed = parsed, accumulator = newAccumulator }


{-| The update function takes an EditRecord and a string, the "text",
breaks the text into a list of logical paragraphs, diffs it with the list
of paragraphs held by the EditRecord, uses `differentialRender` to
render the changed paragraphs while copying the unchanged rendered paragraphs to
produce an updated list of rendered paragraphs. The 'differentialRender'
accomplishes this using the transformer. The seed is used to produces
a differential idList. This last step is perhaps unnecessary. To investigate.
(This was part of an optimization scheme.)
-}
update :
    (String -> List chunk)
    -> (chunk -> parsedChunk)
    -> (Language -> List chunk -> ( acc, List parsedChunk ))
    -> EditRecord chunk parsedChunk acc
    -> String
    -> EditRecord chunk parsedChunk acc
update chunker parser accMaker editRecord text =
    let
        newChunks =
            chunker text

        diffRecord =
            Differ.diff editRecord.chunks newChunks

        parsed_ =
            differentialParser parser diffRecord editRecord

        ( newAccumulator, parsed ) =
            accMaker editRecord.lang newChunks
    in
    -- TODO: real update of accumulator
    { lang = editRecord.lang, chunks = newChunks, parsed = parsed, accumulator = newAccumulator }


differentialParser :
    (chunk -> parsedChunk)
    -> Differ.DiffRecord chunk
    -> EditRecord chunk parsedChunk acc
    -> List parsedChunk
differentialParser parser diffRecord editRecord =
    let
        ii =
            List.length diffRecord.commonInitialSegment

        it =
            List.length diffRecord.commonTerminalSegment

        initialSegmentParsed =
            List.take ii editRecord.parsed

        terminalSegmentParsed =
            takeLast it editRecord.parsed

        middleSegmentParsed =
            List.map parser diffRecord.middleSegmentInTarget
    in
    initialSegmentParsed ++ middleSegmentParsed ++ terminalSegmentParsed


takeLast : Int -> List a -> List a
takeLast k x =
    x |> List.reverse |> List.take k |> List.reverse
