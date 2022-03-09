module Parser.Line exposing (Line, PrimitiveBlockType(..), classify, getNameAndArgs, prefixLength, prefixLengths)

import Compiler.Util
import Parser exposing ((|.), (|=), Parser)
import Parser.Common
import Parser.Language exposing (Language(..))


{-|

    - lineNumber: the line number in the source text
    - position: the position of the first character of the line in the source text

-}
type alias Line =
    { indent : Int, prefix : String, content : String, lineNumber : Int, position : Int }


type PrimitiveBlockType
    = PBVerbatim
    | PBOrdinary
    | PBWhatever


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
                name =
                    Compiler.Util.getMicroLaTeXItem "begin" line.content |> Maybe.withDefault "anon"

                bt =
                    if List.member name Parser.Common.verbatimBlockNames then
                        PBVerbatim

                    else
                        PBOrdinary
            in
            ( bt, Compiler.Util.getMicroLaTeXItem "begin" line.content, Compiler.Util.getBracketedItems line.content )

        L0Lang ->
            if String.left 1 line.content == "|" then
                let
                    words =
                        String.words (String.dropLeft 2 line.content)

                    name =
                        List.head words |> Maybe.withDefault "anon"

                    args =
                        List.drop 1 words
                in
                ( PBOrdinary, Just name, args )

            else if String.left 1 line.content == "||" then
                let
                    words =
                        String.words (String.dropLeft 3 line.content)

                    name =
                        List.head words |> Maybe.withDefault "anon"

                    args =
                        List.drop 1 words
                in
                ( PBVerbatim, Just name, args )

            else
                ( PBOrdinary, Nothing, [] )


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
