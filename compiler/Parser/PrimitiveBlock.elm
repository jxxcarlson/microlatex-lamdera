module Parser.PrimitiveBlock exposing
    ( PrimitiveBlock
    , blockListOfStringList
    , empty
    )

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

import Parser.Language exposing (Language(..))
import Parser.Line as Line exposing (Line, PrimitiveBlockType(..), isEmpty, isNonEmptyBlank)
import Parser.MathMacro exposing (MathExpression(..))
import Tools


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
    Tools.debugLog2 label identity a


report : String -> State -> State
report label a =
    Tools.debugLog2 label (\s -> ( s.lineNumber, s.inVerbatim, Maybe.map .content s.currentBlock )) a


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
    , lang : Language
    , count : Int
    }



-- |> String.join "\n"


blockListOfStringList : Language -> (String -> Bool) -> List String -> List PrimitiveBlock
blockListOfStringList lang isVerbatimLine lines =
    loop (init lang isVerbatimLine lines) nextStep
        |> List.map (\block -> finalize block)
        |> List.map (transform lang isVerbatimLine)
        |> List.concat
        -- TODO: think about the below
        |> List.filter (\block -> block.content /= [ "" ])


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
init : Language -> (String -> Bool) -> List String -> State
init lang isVerbatimLine lines =
    let
        firstLine : Maybe Line
        firstLine =
            List.head lines |> Maybe.map (Line.classify 0 0)

        firstBlock_ : Maybe PrimitiveBlock
        firstBlock_ =
            Maybe.map (blockFromLine lang) firstLine

        firstBlock =
            Maybe.map2 (elaborate lang) firstLine firstBlock_
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
    , lang = lang
    , count = 0
    }


blockFromLine : Language -> Line -> PrimitiveBlock
blockFromLine lang ({ indent, lineNumber, position, prefix, content } as line) =
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
        |> elaborate lang line


nextStep : State -> Step State (List PrimitiveBlock)
nextStep state =
    case List.head state.lines of
        Nothing ->
            case state.currentBlock of
                Nothing ->
                    Done (List.reverse state.blocks)

                Just block ->
                    Done (List.reverse (block :: state.blocks))

        Just rawLine ->
            let
                _ =
                    report1 "nextStep" ( ( state.lineNumber, state.isVerbatimLine rawLine, Maybe.map .blockType state.currentBlock ), rawLine )

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
                    Loop (advance newPosition state)

                -- not in a block, pass over blank, non-empty line
                ( False, False, True ) ->
                    Loop (advance newPosition state)

                -- create a new block: we are not in a block, but
                -- the current line is nonempty and nonblank
                ( False, False, False ) ->
                    Loop (createBlock state currentLine)

                -- A nonempty line was encountered inside a block, so add it
                ( True, False, _ ) ->
                    Loop (addCurrentLineXX state currentLine)

                -- commit the current block: we are in a block and the
                -- current line is empty
                ( True, True, _ ) ->
                    Loop (commitBlock state currentLine)


advance : Int -> State -> State
advance newPosition state =
    { state
        | lines = List.drop 1 state.lines
        , lineNumber = state.lineNumber + 1
        , position = newPosition
        , count = state.count + 1
    }


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
                    Just (addCurrentLine state.lang currentLine block)
            }


commitBlock state currentLine =
    case state.currentBlock of
        Nothing ->
            { state
                | lines = List.drop 1 state.lines
                , indent = currentLine.indent
            }

        Just block ->
            { state
                | lines = List.drop 1 state.lines
                , lineNumber = state.lineNumber + 1
                , position = state.position + String.length currentLine.content
                , count = state.count + 1
                , blocks = block :: state.blocks
                , inBlock = False
                , inVerbatim = state.isVerbatimLine currentLine.content
                , currentBlock = Just (blockFromLine state.lang currentLine)
            }


createBlock state currentLine =
    let
        blocks =
            case state.currentBlock of
                Nothing ->
                    state.blocks

                Just block ->
                    block :: state.blocks

        newBlock =
            Just (blockFromLine state.lang currentLine)
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


addCurrentLine : Language -> Line -> PrimitiveBlock -> PrimitiveBlock
addCurrentLine lang ({ prefix, content, indent } as line) block =
    let
        pb =
            addCurrentLine_ lang line block
    in
    elaborate lang line pb


elaborate : Language -> Line -> PrimitiveBlock -> PrimitiveBlock
elaborate lang line pb =
    if pb.named then
        pb

    else if pb.content == [ "" ] then
        pb

    else
        let
            ( blockType, name, args ) =
                Line.getNameAndArgs lang line
        in
        { pb | blockType = blockType, name = name, args = args, named = True }


addCurrentLine_ : Language -> Line -> PrimitiveBlock -> PrimitiveBlock
addCurrentLine_ lang ({ prefix, content, indent } as line) block =
    { block | content = transformContent lang line :: block.content, sourceText = block.sourceText ++ "\n" ++ prefix ++ content }


transformContent : Language -> Line -> String
transformContent lang ({ indent, prefix, content } as line) =
    if isNonEmptyBlank line then
        case lang of
            L0Lang ->
                "[vskip 10]"

            MicroLaTeXLang ->
                "\\vskip{10}"

            XMarkdownLang ->
                "@vskip[10]"

    else
        prefix ++ content


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



-- TRANSFORMS


isMathBlock : PrimitiveBlock -> Bool
isMathBlock block =
    List.member (List.head block.content) [ Just "\\begin{equation}", Just "\\begin{aligned}", Just "\\begin{code}" ]


transform : Language -> (String -> Bool) -> PrimitiveBlock -> List PrimitiveBlock
transform lang isVerbatim block =
    case lang of
        MicroLaTeXLang ->
            if isMathBlock block then
                [ block ]

            else
                case Maybe.map isBegin (List.head block.content) of
                    Just True ->
                        extractMicroLaTeXEnvironment block |> blockListOfStringList L0Lang isVerbatim

                    _ ->
                        [ block ]

        _ ->
            [ block ]


extractMicroLaTeXEnvironment : PrimitiveBlock -> List String
extractMicroLaTeXEnvironment { content } =
    transformToL0 content


type alias IndentationData =
    { indent : Int, input : List String, output : List String }


transformToL0 : List String -> List String
transformToL0 strings =
    strings |> indentStrings |> transformToL0Aux


indentStrings : List String -> List String
indentStrings strings =
    indentAux { indent = -1, input = strings, output = [] } |> .output |> List.reverse


indentAux : IndentationData -> IndentationData
indentAux ({ indent, input, output } as data) =
    case input of
        [] ->
            data

        first :: rest ->
            let
                newIndent =
                    if isBegin first then
                        indent + 1

                    else if isEnd first then
                        indent - 1

                    else
                        indent

                newOutput =
                    if isEnd first then
                        indentString indent first :: output

                    else
                        indentString newIndent first :: output
            in
            indentAux { data | output = newOutput, input = rest, indent = newIndent }


indentString : Int -> String -> String
indentString k str =
    String.repeat (2 * k) " " ++ str


transformToL0Aux : List String -> List String
transformToL0Aux strings =
    let
        mapper str =
            let
                bareString =
                    String.trimLeft str

                prefix =
                    String.replace bareString "" str
            in
            if isBegin bareString then
                case Parser.MathMacro.parseOne str of
                    Just (Macro "begin" [ MathList [ MathText blockName ] ]) ->
                        [ "", prefix ++ "| " ++ blockName ]

                    _ ->
                        [ "", prefix ++ "| theorem" ]

            else if isEnd bareString then
                [ "" ]

            else
                [ str ]
    in
    strings |> List.map mapper |> List.concat


isBegin : String -> Bool
isBegin str =
    String.left 6 (String.trimLeft str) == "\\begin"


isEnd : String -> Bool
isEnd str =
    String.left 4 (String.trimLeft str) == "\\end"
