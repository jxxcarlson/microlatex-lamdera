module MicroLaTeX.Parser.PrimitiveBlock exposing (..)

{-| This module is like Tree.Blocks, except that if the first line of a block
is deemed to signal the beginning of a "verbatim block," all succeeding lines will be
incorporated in it, so long as their indentation level is greater than or equal to the
indentation level of the first line. To make this work, function fromStringAsParagraphs
requires an additional argument:

    fromStringAsParagraphs :
        (String -> Bool)
        -> String
        -> List Block

The additional argument is a predicate which determines whether a line to be
considered the first line of a verbatim block.

@docs Block, fromStringAsLines, fromStringAsParagraphs, quantumOfBlocks

-}

--- (PrimitiveBlock, empty, toPrimitiveBlocks)

import Compiler.Util
import List.Extra
import MicroLaTeX.Parser.Line as Line exposing (Line, PrimitiveBlockType(..), isEmpty, isNonEmptyBlank)
import MicroLaTeX.Parser.TransformLaTeX exposing (toL0)
import Parser.Language exposing (Language(..))
import Parser.TextMacro as TextMacro exposing (MyMacro(..))
import Tools exposing (..)


{-| -}
type alias PrimitiveBlock =
    { indent : Int
    , lineNumber : Int
    , position : Int
    , content : List String
    , name : Maybe String
    , args : List String
    , named : Bool
    , sourceText : String
    , blockType : PrimitiveBlockType
    }


report1 : String -> ( ( Int, Bool, Maybe PrimitiveBlockType ), String ) -> ( ( Int, Bool, Maybe PrimitiveBlockType ), String )
report1 label a =
    -- Tools.debugLog2 label identity a
    identity a


report2 : String -> State -> State
report2 label a =
    -- Tools.debugLog2 label (\s -> ( s.lineNumber, s.inVerbatim, Maybe.map .content s.currentBlock )) a
    identity a


empty : PrimitiveBlock
empty =
    { indent = 0
    , lineNumber = 0
    , position = 0
    , content = [ "???" ]
    , name = Nothing
    , args = []
    , named = False
    , sourceText = "???"
    , blockType = PBParagraph
    }


type alias State =
    { blocks : List PrimitiveBlock
    , currentBlock : Maybe PrimitiveBlock
    , lines : List String
    , inBlock : Bool
    , indent : Int
    , lineNumber : Int
    , position : Int
    , inVerbatim : Bool
    , isVerbatimLine : String -> Bool
    , count : Int
    , label : String
    }



-- |> String.join "\n"


toPrimitiveBlocks : (String -> Bool) -> List String -> List PrimitiveBlock
toPrimitiveBlocks isVerbatimLine lines =
    lines |> toPrimitiveBlocks_ isVerbatimLine


toPrimitiveBlocks_ : (String -> Bool) -> List String -> List PrimitiveBlock
toPrimitiveBlocks_ isVerbatimLine lines =
    loop (init isVerbatimLine lines) nextStep
        |> List.map (\block -> finalize block)



--|> List.map (transform lang isVerbatimLine)
--|> List.concat
-- TODO: think about the below
-- |> List.filter (\block -> block.content /= [ "" ])


finalize : PrimitiveBlock -> PrimitiveBlock
finalize block =
    let
        content =
            List.reverse block.content

        sourceText =
            String.join "\n" content
    in
    { block | content = content, sourceText = sourceText }


{-|

    Recall: classify position lineNumber, where position
    is the position of the first charabcter in the source
    and lineNumber is the index of the current line in the source

-}
init : (String -> Bool) -> List String -> State
init isVerbatimLine lines =
    let
        firstLine : Maybe Line
        firstLine =
            List.head lines |> Maybe.map (Line.classify 0 0)

        firstBlock_ : Maybe PrimitiveBlock
        firstBlock_ =
            Maybe.map blockFromLine firstLine

        firstBlock =
            Maybe.map2 elaborate firstLine firstBlock_
    in
    { blocks = []
    , currentBlock = Nothing
    , lines = lines
    , indent = 0
    , lineNumber = 0
    , inBlock = False
    , position = 0
    , inVerbatim = False
    , isVerbatimLine = isVerbatimLine
    , count = 0
    , label = "0, START"
    }


blockFromLine : Line -> PrimitiveBlock
blockFromLine ({ indent, lineNumber, position, prefix, content } as line) =
    let
        ( blockType, name, newContent ) =
            case TextMacro.get line.content of
                Err _ ->
                    ( PBParagraph, Nothing, content )

                Ok (MyMacro "begin" (name_ :: rest)) ->
                    ( PBOrdinary, Just name_, "| " ++ name_ )

                _ ->
                    ( PBParagraph, Nothing, content )
    in
    { indent = indent
    , lineNumber = lineNumber
    , position = position
    , content = [ prefix ++ newContent ]
    , name = name
    , args = []
    , named = not (name == Nothing)
    , sourceText = ""
    , blockType = blockType
    }
        |> elaborate line


nextStep : State -> Step State (List PrimitiveBlock)
nextStep state =
    case List.head state.lines of
        Nothing ->
            -- Nothing left to parse, finish up
            case state.currentBlock of
                Nothing ->
                    Done (List.reverse state.blocks)

                Just block ->
                    let
                        blocks =
                            if block.content == [ "" ] then
                                -- Debug.log (Tools.cyan "****, DONE" 13)
                                List.reverse state.blocks

                            else
                                -- Debug.log (Tools.cyan "****, DONE" 13)
                                List.reverse (block :: state.blocks)
                    in
                    Done blocks

        Just rawLine ->
            -- process line
            let
                --_ =
                --    report state
                newPosition =
                    if rawLine == "" then
                        state.position + 1

                    else
                        state.position + String.length rawLine + 1

                currentLine : Line
                currentLine =
                    -- TODO: the below is wrong
                    Line.classify state.position (state.lineNumber + 1) rawLine
            in
            case ( state.inBlock, isEmpty currentLine, isNonEmptyBlank currentLine ) of
                -- not in a block, pass over empty line
                ( False, True, _ ) ->
                    Loop (advance newPosition { state | label = "1, EMPTY" })

                -- not in a block, pass over blank, non-empty line
                ( False, False, True ) ->
                    Loop (advance newPosition { state | label = "2, PASS" })

                -- create a new block: we are not in a block, but
                -- the current line is nonempty and nonblank
                ( False, False, False ) ->
                    Loop (createBlock { state | label = "3, NEW" } currentLine)

                -- A nonempty line was encountered inside a block, so add it
                ( True, False, _ ) ->
                    Loop (addCurrentLineXX { state | label = "4, ADD" } currentLine)

                -- commit the current block: we are in a block and the
                -- current line is empty
                ( True, True, _ ) ->
                    Loop (commitBlock { state | label = "5, COMMIT" } currentLine)



--
--report state =
--    let
--        prefix =
--            String.fromInt state.lineNumber ++ ". " ++ state.label
--
--        contentOfCurrentBlock : Maybe (List String)
--        contentOfCurrentBlock =
--            Maybe.map .content state.currentBlock
--
--        _ =
--            Debug.log (Tools.cyan prefix 13) { curr = contentOfCurrentBlock, theBlocks = List.map .content state.blocks }
--    in
--    1


advance : Int -> State -> State
advance newPosition state =
    { state
        | lines = List.drop 1 state.lines
        , lineNumber = state.lineNumber + 1
        , position = newPosition
        , count = state.count + 1
    }


addCurrentLineXX : State -> Line -> State
addCurrentLineXX state currentLine =
    case state.currentBlock of
        Nothing ->
            { state | lines = List.drop 1 state.lines }

        Just block ->
            { state
                | lines = List.drop 1 state.lines
                , lineNumber = state.lineNumber + 1
                , position = state.position + String.length currentLine.content
                , count = state.count + 1
                , currentBlock =
                    Just (addCurrentLine currentLine block)
            }


commitBlock : State -> Line -> State
commitBlock state currentLine =
    let
        lastLine =
            Maybe.map .content state.currentBlock |> Maybe.andThen List.head |> Maybe.withDefault "--"

        name2 =
            case TextMacro.get lastLine of
                Err _ ->
                    Nothing

                Ok (MyMacro "end" (name_ :: rest)) ->
                    Just name_

                _ ->
                    Nothing
    in
    case state.currentBlock of
        Nothing ->
            { state
                | lines = List.drop 1 state.lines
                , indent = currentLine.indent
            }

        Just block ->
            let
                foo =
                    block

                adjustedBlock =
                    if block.content == [ "" ] then
                        block

                    else if block.name == Nothing then
                        block

                    else if block.name == name2 then
                        { block | content = "" :: List.drop 1 block.content }

                    else
                        block
            in
            { state
                | lines = List.drop 1 state.lines
                , lineNumber = state.lineNumber + 1
                , position = state.position + String.length currentLine.content
                , count = state.count + 1
                , blocks = adjustedBlock :: state.blocks
                , inBlock = False
                , inVerbatim = state.isVerbatimLine currentLine.content
                , currentBlock = Just (blockFromLine currentLine) -- TODO: is this correct?
            }



--
--commitBlockOLD state currentLine =
--    case state.currentBlock of
--        Nothing ->
--            { state
--                | lines = List.drop 1 state.lines
--                , indent = currentLine.indent
--            }
--
--        Just block ->
--            let
--                ( currentBlock, newBlocks ) =
--                    if block.content == [ "" ] then
--                        ( Nothing, state.blocks )
--
--                    else
--                        ( Just (blockFromLine state.lang currentLine), block :: state.blocks )
--            in
--            { state
--                | lines = List.drop 1 state.lines
--                , lineNumber = state.lineNumber + 1
--                , position = state.position + String.length currentLine.content
--                , count = state.count + 1
--                , blocks = newBlocks
--                , inBlock = False
--                , inVerbatim = state.isVerbatimLine currentLine.content
--                , currentBlock = currentBlock
--            }


createBlock state currentLine =
    let
        blocks =
            case state.currentBlock of
                Nothing ->
                    state.blocks

                -- When creating a new block push the current block onto state.blocks
                -- only if its content is nontrivial (not == [""])
                Just block ->
                    if block.content == [ "" ] then
                        state.blocks

                    else
                        block :: state.blocks

        newBlock =
            Just (blockFromLine currentLine)
    in
    { state
        | lines = List.drop 1 state.lines
        , lineNumber = state.lineNumber + 1
        , position = state.position + String.length currentLine.content
        , count = state.count + 1
        , indent = currentLine.indent
        , inBlock = True
        , currentBlock = newBlock
        , blocks = blocks
    }


addCurrentLine : Line -> PrimitiveBlock -> PrimitiveBlock
addCurrentLine ({ prefix, content, indent } as line) block =
    let
        pb =
            addCurrentLine_ line block
    in
    elaborate line pb


elaborate : Line -> PrimitiveBlock -> PrimitiveBlock
elaborate line pb =
    if pb.named then
        pb

    else if pb.content == [ "" ] then
        pb

    else
        let
            ( blockType, name, args ) =
                -- TODO: note this change: it needs to be verified
                Line.getNameAndArgs L0Lang line
        in
        { pb | blockType = blockType, name = name, args = args, named = True }


addCurrentLine_ : Line -> PrimitiveBlock -> PrimitiveBlock
addCurrentLine_ ({ prefix, content, indent } as line) block =
    { block | content = content :: block.content, sourceText = block.sourceText ++ "\n" ++ prefix ++ content }


transformContent : Language -> Line -> String
transformContent lang ({ indent, prefix, content } as line) =
    --if isNonEmptyBlank line then
    --    "[syspar]"
    --
    --else
    --    prefix ++ content
    -- TODO: temporarily disabled
    content


type Step state a
    = Loop state
    | Done a


loop : state -> (state -> Step state a) -> a
loop s f =
    case f s of
        Loop s_ ->
            loop s_ f

        Done b ->
            b



-- EXAMPLES


a1 =
    """
abc
def

ghi
jkl
"""


a2 =
    """
abc
def

  ghi
  jkl
"""


a3 =
    """
\\begin{theorem}
abc
def
\\end{theorem}
"""


a4 =
    """
\\begin{theorem}
This is a very good theorem

  $$
  x^2
  $$

  Isn't that nice?

\\end{theorem}
"""
