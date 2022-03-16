module Parser.PrimitiveBlock exposing
    ( PrimitiveBlock
    , blockListOfStringList
    , empty
    , idem
    , lidem
    , lidem2
    , lpb
    , midem
    , midem2
    , mpb
    , toString
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
import Parser.Line as Line exposing (Line, PrimitiveBlockType(..))
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
        |> List.filter (\block -> block.content /= [])


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
    , currentBlock = firstBlock
    , lines = List.drop 1 lines
    , indent = 0
    , lineNumber = 0
    , position = String.length (Maybe.map .content firstBlock |> Maybe.andThen List.head |> Maybe.withDefault "")
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

                newLineNumber =
                    state.lineNumber + 1

                currentLine =
                    -- TODO: the below is wrong
                    Line.classify state.position newLineNumber rawLine

                newState =
                    { state | lineNumber = newLineNumber, position = newPosition, count = state.count + 1 }
            in
            case compare currentLine.indent state.indent of
                GT ->
                    Loop <| handleGT currentLine newState

                EQ ->
                    Loop <| handleEQ currentLine newState

                LT ->
                    Loop <| handleLT currentLine newState


indentationOf k =
    String.repeat k " "


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
    let
        newIndent =
            if block.indent == 0 && indent > 0 then
                indent

            else
                block.indent
    in
    { block | indent = newIndent, content = (prefix ++ content) :: block.content, sourceText = block.sourceText ++ "\n" ++ prefix ++ content }


handleGT : Line -> State -> State
handleGT currentLine state =
    case state.currentBlock of
        Nothing ->
            { state | lines = List.drop 1 state.lines, indent = currentLine.indent } |> report "GT, 1"

        Just block ->
            if state.inVerbatim then
                -- add line to current block
                let
                    leadingSpaces =
                        indentationOf (currentLine.indent - state.indent)
                in
                { state
                    | lines = List.drop 1 state.lines
                    , currentBlock =
                        Just (addCurrentLine state.lang currentLine block)
                }
                    |> report "GT, 2"

            else
                -- make new block
                { state
                    | lines = List.drop 1 state.lines
                    , position = state.position + String.length currentLine.content
                    , indent = currentLine.indent
                    , blocks = block :: state.blocks
                    , currentBlock = Just (blockFromLine state.lang currentLine)
                }
                    |> report "GT, 3"


handleEQ : Line -> State -> State
handleEQ currentLine state =
    case state.currentBlock of
        Nothing ->
            { state | lines = List.drop 1 state.lines }

        Just block ->
            if currentLine.content == "" then
                -- make new block and reset inVerbatim
                { state
                    | lines = List.drop 1 state.lines
                    , position = state.position + String.length currentLine.content
                    , indent = currentLine.indent
                    , blocks = block :: state.blocks
                    , inVerbatim = state.isVerbatimLine currentLine.content
                    , currentBlock = Just (blockFromLine state.lang currentLine)
                }
                    |> report "EQ, 1"

            else if state.isVerbatimLine currentLine.content then
                -- add the current line to the block and keep the indentation level
                { state
                    | lines = List.drop 1 state.lines
                    , inVerbatim = True
                    , currentBlock =
                        Just
                            (addCurrentLine state.lang currentLine block)
                }
                    |> report "EQ, 2"

            else
                -- add the current line to the block
                { state
                    | lines = List.drop 1 state.lines
                    , indent = currentLine.indent
                    , currentBlock =
                        Just
                            (addCurrentLine state.lang currentLine block)
                }
                    |> report "EQ, 3"


handleLT : Line -> State -> State
handleLT currentLine state =
    case state.currentBlock of
        Nothing ->
            { state
                | lines = List.drop 1 state.lines
                , indent = currentLine.indent
            }
                |> report "LT, 1"

        Just block ->
            -- TODO: explain and examine currentBlock = ..
            --{ state
            --    | lines = List.drop 1 state.lines
            --    , indent = currentLine.indent
            --    , blocks = block :: state.blocks
            --    , currentBlock = Nothing -- TODO ??
            --}
            -- make new block and reset inVerbatim
            { state
                | lines = List.drop 1 state.lines
                , position = state.position + String.length currentLine.content
                , indent = currentLine.indent
                , blocks = block :: state.blocks
                , inVerbatim = state.isVerbatimLine currentLine.content
                , currentBlock = Just (blockFromLine state.lang currentLine)
            }
                |> report "LT, 2"


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



-- FOR TESTING


mpb : String -> List PrimitiveBlock
mpb str =
    str |> String.lines |> blockListOfStringList MicroLaTeXLang (\_ -> True)


lpb : String -> List PrimitiveBlock
lpb str =
    str |> String.lines |> blockListOfStringList L0Lang (\_ -> True)


midem =
    idem MicroLaTeXLang


lidem =
    idem L0Lang


midem2 =
    idem2 MicroLaTeXLang


lidem2 =
    idem2 L0Lang


idem : Language -> String -> Bool
idem lang str =
    str == (str |> String.lines |> blockListOfStringList lang (\_ -> True) |> toString)


idem2 : Language -> String -> Bool
idem2 lang str =
    str == (str |> String.lines |> blockListOfStringList lang (\_ -> True) |> toString2)


toString : List { a | content : List String } -> String
toString blocks =
    blocks |> List.map (.content >> String.join "\n") |> String.join "\n"


toString2 : List { a | sourceText : String } -> String
toString2 blocks =
    blocks |> List.map .sourceText |> String.join "\n"



-- TOOLS


greatestCommonPrefix : String -> String -> String
greatestCommonPrefix a b =
    let
        p =
            greatestCommonPrefixAux a b (String.length a)
    in
    String.left p a


greatestCommonPrefixAux : String -> String -> Int -> Int
greatestCommonPrefixAux a b n =
    if String.left n a == String.left n b then
        n

    else if n == 0 then
        0

    else
        greatestCommonPrefixAux (String.left (n - 1) a) (String.left (n - 1) b) (n - 1)
