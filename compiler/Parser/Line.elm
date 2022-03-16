module Parser.Line exposing (Line, PrimitiveBlockType(..), classify, getNameAndArgs, isEmpty, isNonEmptyBlank, prefixLength, prefixLengths)

import Compiler.Util
import Parser exposing ((|.), (|=), Parser)
import Parser.Common
import Parser.Language exposing (Language(..))


{-|

    - ident:      the number of blanks before the first non-blank
    - prefix:     the string of blanks preceding the first non-blank
    - content:    the original string with the prefix removed
    - lineNumber: the line number in the source text
    - position:   the position of the first character of the line in the source text

-}
type alias Line =
    { indent : Int, prefix : String, content : String, lineNumber : Int, position : Int }


type PrimitiveBlockType
    = PBVerbatim
    | PBOrdinary
    | PBParagraph


isEmpty : Line -> Bool
isEmpty line =
    line.indent == 0 && line.content == ""


isNonEmptyBlank : Line -> Bool
isNonEmptyBlank line =
    line.indent > 0 && line.content == ""


classify : Int -> Int -> String -> Line
classify position lineNumber str =
    case Parser.run (prefixParser position lineNumber) str of
        Err _ ->
            { indent = 0, content = "!!ERROR", prefix = "", position = position, lineNumber = lineNumber }

        Ok result ->
            result


getNameAndArgs : Language -> Line -> ( PrimitiveBlockType, Maybe String, List String )
getNameAndArgs lang line =
    case lang of
        MicroLaTeXLang ->
            let
                normalizedLine =
                    String.trim line.content

                name =
                    case Compiler.Util.getMicroLaTeXItem "begin" normalizedLine of
                        Just str ->
                            Just str

                        Nothing ->
                            if normalizedLine == "$$" then
                                Just "math"

                            else
                                Nothing

                bt =
                    if name == Nothing then
                        PBParagraph

                    else if List.member (name |> Maybe.withDefault "---") Parser.Common.verbatimBlockNames || normalizedLine == "$$" then
                        PBVerbatim

                    else
                        PBOrdinary
            in
            ( bt, name, Compiler.Util.getBracketedItems normalizedLine )

        L0Lang ->
            let
                normalizedLine =
                    String.trim line.content

                -- account for possible indentation
            in
            if String.left 2 normalizedLine == "||" then
                let
                    words =
                        String.words (String.dropLeft 3 normalizedLine)

                    name =
                        List.head words |> Maybe.withDefault "anon"

                    args =
                        List.drop 1 words
                in
                ( PBVerbatim, Just name, args )

            else if String.left 1 normalizedLine == "|" then
                let
                    words =
                        String.words (String.dropLeft 2 normalizedLine)

                    name =
                        List.head words |> Maybe.withDefault "anon"

                    args =
                        List.drop 1 words
                in
                ( PBOrdinary, Just name, args )

            else if String.left 2 line.content == "$$" then
                ( PBVerbatim, Just "math", [] )

            else
                ( PBParagraph, Nothing, [] )

        XMarkdownLang ->
            -- TODO: implement this
            if String.left 3 line.content == "```" then
                ( PBVerbatim, Just "code", [] )

            else if String.left 2 line.content == "$$" then
                ( PBVerbatim, Just "math", [] )

            else
                ( PBParagraph, Nothing, [] )


prefixLength : Int -> Int -> String -> Int
prefixLength position lineNumber str =
    classify position lineNumber str |> .indent


prefixLengths : Int -> Int -> List String -> List Int
prefixLengths position lineNumber strs =
    strs |> List.map (prefixLength position lineNumber) |> List.filter (\n -> n /= 0)


{-|

    The prefix is the first word of the line

-}
prefixParser : Int -> Int -> Parser Line
prefixParser position lineNumber =
    Parser.succeed (\prefixStart prefixEnd lineEnd content -> { indent = prefixEnd - prefixStart, prefix = String.slice 0 prefixEnd content, content = String.slice prefixEnd lineEnd content, position = position, lineNumber = lineNumber })
        |= Parser.getOffset
        |. Parser.chompWhile (\c -> c == ' ')
        |= Parser.getOffset
        |. Parser.chompWhile (\c -> c /= '\n')
        |= Parser.getOffset
        |= Parser.getSource
