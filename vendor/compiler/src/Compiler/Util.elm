module Compiler.Util exposing (eraseItem, getItem)

import Parser exposing ((|.), (|=), Parser)
import Parser.Language exposing (Language(..))


{-|

    > getItem MicroLaTeXLang "foo" "... whatever ... \\foo{bar} ... whatever else ..."
    "bar" : String

    > getItem L0Lang "foo" "... whatever ... [foo bar] ... whatever else ..."
    "bar" : String

-}
getItem : Language -> String -> String -> String
getItem language key str =
    case language of
        L0Lang ->
            runParser (keyValParser key) str ""

        MicroLaTeXLang ->
            runParser (macroValParser key) str ""


{-|

    > eraseItem MicroLaTeXLang "foo" "bar" "... whatever\\foo{bar}\n, whatever else ..."
    "... whatever, whatever else ..." : String

    > eraseItem L0Lang "foo" "bar" "... whateve[foo bar]\n, whatever else ..."
    "... whatever, whatever else ..." : String

-}
eraseItem : Language -> String -> String -> String -> String
eraseItem language key value str =
    case language of
        L0Lang ->
            let
                target =
                    "[" ++ key ++ " " ++ value ++ "]\n"
            in
            String.replace target "" str

        MicroLaTeXLang ->
            let
                target =
                    "\\" ++ key ++ "{" ++ value ++ "}\n"
            in
            String.replace target "" str


runParser stringParser str default =
    case Parser.run stringParser str of
        Ok s ->
            s

        Err _ ->
            default


{-|

    > Parser.run macroValParser "... whatever ... \\foo{bar} ... whatever else ..."
    Ok "bar"

-}
macroValParser : String -> Parser String
macroValParser macroName =
    (Parser.succeed String.slice
        |. Parser.chompUntil ("\\" ++ macroName ++ "{")
        |. Parser.symbol ("\\" ++ macroName ++ "{")
        |. Parser.spaces
        |= Parser.getOffset
        |. Parser.chompUntil "}"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map String.trim


{-|

    > Parser.run macroValParser "... whatever ... \\foo{bar} ... whatever else ..."
    Ok "bar"

-}
keyValParser : String -> Parser String
keyValParser key =
    (Parser.succeed String.slice
        |. Parser.chompUntil ("[" ++ key ++ " ")
        |. Parser.symbol ("[" ++ key ++ " ")
        |. Parser.spaces
        |= Parser.getOffset
        |. Parser.chompUntil "]"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map String.trim
