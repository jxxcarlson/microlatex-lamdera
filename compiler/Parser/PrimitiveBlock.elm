module Parser.PrimitiveBlock exposing
    ( PrimitiveBlock
    , blockListOfStringList
    , idem
    , lidem
    , lt
    , midem
    , mt
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
import Parser.Line as Line exposing (Line)


{-| -}
type alias PrimitiveBlock =
    { indent : Int
    , lineNumber : Int
    , position : Int
    , content : List String
    , name : Maybe String
    , args : List String
    , named : Bool
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
    }


mt str =
    str |> String.lines |> blockListOfStringList MicroLaTeXLang (\_ -> True)


lt str =
    str |> String.lines |> blockListOfStringList L0Lang (\_ -> True)


midem =
    idem MicroLaTeXLang


lidem =
    idem L0Lang


idem : Language -> String -> Bool
idem lang str =
    str == (str |> String.lines |> blockListOfStringList lang (\_ -> True) |> toString)


toString : List { a | content : List String } -> String
toString blocks =
    blocks |> List.map (.content >> String.join "\n") |> String.join "\n"



-- |> String.join "\n"


blockListOfStringList : Language -> (String -> Bool) -> List String -> List PrimitiveBlock
blockListOfStringList lang isVerbatimLine lines =
    loop (init lang isVerbatimLine lines) nextStep
        |> List.map (\block -> { block | content = List.reverse block.content })


{-|

    Recall: classify position lineNumber, where position
    is the position of the first charabcter in the source
    and lineNumber is the index of the current line in the source

-}
init : Language -> (String -> Bool) -> List String -> State
init lang isVerbatimLine lines =
    let
        firstBlock =
            List.head lines |> Maybe.map (Line.classify 0 0 >> blockFromLine lang)
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
    }


blockFromLine : Language -> Line -> PrimitiveBlock
blockFromLine lang { indent, lineNumber, position, prefix, content } =
    { indent = indent, lineNumber = lineNumber, position = position, content = [ prefix ++ content ], name = Nothing, args = [], named = False }


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
                newPosition =
                    if rawLine == "" then
                        state.position + 1

                    else
                        state.position + String.length rawLine + 1

                newLineNumber =
                    state.lineNumber + 1

                _ =
                    Debug.log "n, p, r" ( newLineNumber, newPosition, rawLine )

                currentLine =
                    -- TODO: the below is wrong
                    Line.classify state.position newLineNumber rawLine

                newState =
                    { state | lineNumber = newLineNumber, position = newPosition }
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
        _ =
            Debug.log "add current line" content

        newIndent =
            if block.indent == 0 && indent > 0 then
                indent

            else
                block.indent
    in
    if block.named then
        { block | indent = newIndent, content = (prefix ++ content) :: block.content }

    else
        let
            ( name, args ) =
                Line.getNameAndArgs lang line
        in
        { block | indent = newIndent, content = (prefix ++ content) :: block.content, name = name, args = args, named = True }


handleGT : Line -> State -> State
handleGT currentLine state =
    case state.currentBlock of
        Nothing ->
            { state | lines = List.drop 1 state.lines, indent = currentLine.indent }

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

            else
                -- make new block
                { state
                    | lines = List.drop 1 state.lines
                    , position = state.position + String.length currentLine.content
                    , indent = currentLine.indent
                    , blocks = block :: state.blocks
                    , currentBlock = Just (blockFromLine state.lang currentLine)
                }


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

            else if state.isVerbatimLine currentLine.content then
                -- add the current line to the block and keep the indentation level
                { state
                    | lines = List.drop 1 state.lines
                    , inVerbatim = True
                    , currentBlock =
                        Just
                            (addCurrentLine state.lang currentLine block)
                }

            else
                -- add the current line to the block
                { state
                    | lines = List.drop 1 state.lines
                    , indent = currentLine.indent
                    , currentBlock =
                        Just
                            (addCurrentLine state.lang currentLine block)
                }


handleLT : Line -> State -> State
handleLT currentLine state =
    case state.currentBlock of
        Nothing ->
            { state
                | lines = List.drop 1 state.lines
                , indent = currentLine.indent
            }

        Just block ->
            -- TODO: explain and examine currentBlock = ..
            { state
                | lines = List.drop 1 state.lines
                , indent = currentLine.indent
                , blocks = block :: state.blocks
                , currentBlock = Nothing -- TODO ??
            }


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
