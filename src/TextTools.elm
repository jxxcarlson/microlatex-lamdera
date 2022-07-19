module TextTools exposing (getElement, getItem, getRawItem, macroValParser, runParser)

import Parser exposing ((|.), (|=), Parser)
import Parser.Language exposing (Language(..))


getItem : Language -> String -> String -> String
getItem language key str =
    -- TODO: review this
    case language of
        -- TODO: deal with the XX's
        L0Lang ->
            getElement key str

        MicroLaTeXLang ->
            runParser (macroValParser key) str ("XX:" ++ key)

        PlainTextLang ->
            "XX:" ++ key

        XMarkdownLang ->
            "XX:" ++ key


{-|

    > run (rawElementParser "title") "o [tags foo, bar] ho ho ho [title    Foo] blah blah"
    Ok ("[title    Foo]")

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


runParser stringParser str default =
    case Parser.run stringParser str of
        Ok s ->
            s

        Err _ ->
            default


getElement : String -> String -> String
getElement itemName source =
    case Parser.run (elementParser itemName) source of
        Err _ ->
            ""

        Ok str ->
            str


{-|

    > getItem "title" "o [foo bar] ho ho ho [title Foo] blah blah"
    "Foo" : String

-}
elementParser : String -> Parser String
elementParser name =
    Parser.succeed String.slice
        |. Parser.chompUntil "["
        |. Parser.chompUntil name
        |. Parser.symbol name
        |. Parser.spaces
        |= Parser.getOffset
        |. Parser.chompUntil "]"
        |= Parser.getOffset
        |= Parser.getSource


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
