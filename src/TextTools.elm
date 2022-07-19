module TextTools exposing (getRawItem)

import Parser exposing ((|.), (|=), Parser)
import Parser.Language exposing (Language(..))


getRawItem : Language -> String -> String -> Maybe String
getRawItem language key str =
    case language of
        L0Lang ->
            Parser.run (rawElementParser key) str |> Result.toMaybe

        MicroLaTeXLang ->
            Parser.run (rawMacroParser key) str |> Result.toMaybe

        PlainTextLang ->
            Nothing

        XMarkdownLang ->
            Parser.run (rawXMarkdownElementParser key) str |> Result.toMaybe


{-|

    > getItem "title" "o [foo bar] ho ho ho [title Foo] blah blah"
    "[title Foo]" : String

-}
rawElementParser : String -> Parser String
rawElementParser name =
    (Parser.succeed String.slice
        |. Parser.chompUntil "["
        |. Parser.chompUntil name
        |= Parser.getOffset
        |. Parser.symbol name
        |. Parser.spaces
        |. Parser.chompUntil "]"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map (\s -> "[" ++ s ++ "]")


rawXMarkdownElementParser : String -> Parser String
rawXMarkdownElementParser name =
    (Parser.succeed String.slice
        |. Parser.chompUntil "@["
        |. Parser.chompUntil name
        |= Parser.getOffset
        |. Parser.symbol name
        |. Parser.spaces
        |. Parser.chompUntil "]"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map (\s -> "[" ++ s ++ "]")


{-|

    > run (rawMacroParser "tags") "foo bar\n\n \\title{abc} djfdkj \\tags{foo,    bar} djlfja;d"
    Ok ("\\tags{foo,    bar}")

-}
rawMacroParser : String -> Parser String
rawMacroParser macroName =
    (Parser.succeed String.slice
        |. Parser.chompUntil ("\\" ++ macroName ++ "{")
        |. Parser.symbol ("\\" ++ macroName ++ "{")
        |= Parser.getOffset
        |. Parser.spaces
        |. Parser.chompUntil "}"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map (\s -> "\\" ++ macroName ++ "{" ++ s ++ "}")
