module Parser.PrimitiveBlock exposing (PrimitiveBlock, empty, parse)

{-| The main function is

    parse : Language -> (String -> Bool) -> List String -> List PrimitiveBlock

@docs PrimitiveBlock, empty, parse

-}

import MicroLaTeX.Parser.TransformLaTeX exposing (toL0)
import Parser.Language exposing (Language(..))
import Parser.Line as Line exposing (Line, PrimitiveBlockType(..), isEmpty, isNonEmptyBlank)


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


{-| Parse a list of strings into a list of primitive blocks given a markup
language and a function for determining when a string is the first line
of a verbatim block
-}
parse : Language -> (String -> Bool) -> List String -> List PrimitiveBlock
parse lang isVerbatimLine lines =
    if lang == MicroLaTeXLang then
        lines |> toL0 |> runLoop isVerbatimLine

    else
        lines |> runLoop isVerbatimLine


runLoop : (String -> Bool) -> List String -> List PrimitiveBlock
runLoop isVerbatimLine lines =
    loop (init isVerbatimLine lines) nextStep
        |> List.map (\block -> finalize block)



-- TODO: think about the below


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
    { indent = indent
    , lineNumber = lineNumber
    , position = position
    , content = [ prefix ++ content ]
    , name = Nothing
    , args = []
    , named = False
    , sourceText = ""
    , blockType = PBParagraph
    }
        |> elaborate line


nextStep : State -> Step State (List PrimitiveBlock)
nextStep state =
    case List.head state.lines of
        Nothing ->
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
                    Loop (addCurrentLine2 { state | label = "4, ADD" } currentLine)

                -- commit the current block: we are in a block and the
                -- current line is empty
                ( True, True, _ ) ->
                    Loop (commitBlock { state | label = "5, COMMIT" } currentLine)


advance : Int -> State -> State
advance newPosition state =
    { state
        | lines = List.drop 1 state.lines
        , lineNumber = state.lineNumber + 1
        , position = newPosition
        , count = state.count + 1
    }


addCurrentLine2 : State -> Line -> State
addCurrentLine2 state currentLine =
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
    case state.currentBlock of
        Nothing ->
            { state
                | lines = List.drop 1 state.lines
                , indent = currentLine.indent
            }

        Just block ->
            let
                ( currentBlock, newBlocks ) =
                    if block.content == [ "" ] then
                        ( Nothing, state.blocks )

                    else
                        ( Just (blockFromLine currentLine), block :: state.blocks )
            in
            { state
                | lines = List.drop 1 state.lines
                , lineNumber = state.lineNumber + 1
                , position = state.position + String.length currentLine.content
                , count = state.count + 1
                , blocks = newBlocks
                , inBlock = False
                , inVerbatim = state.isVerbatimLine currentLine.content
                , currentBlock = currentBlock
            }


createBlock : State -> Line -> State
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
    { block | content = line.content :: block.content, sourceText = block.sourceText ++ "\n" ++ prefix ++ content }


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
