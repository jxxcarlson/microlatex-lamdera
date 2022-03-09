module Compiler.Util exposing (depth, eraseItem, getBracketedItem, getBracketedItems, getItem, getMicroLaTeXItem, size)

import Parser exposing ((|.), (|=), Parser, Step(..), loop, map, oneOf, spaces, succeed)
import Parser.Language exposing (Language(..))
import Tree exposing (Tree)


{-| Apply a parser zero or more times and return a list of the results.
-}
many : Parser a -> Parser (List a)
many p =
    loop [] (manyHelp p)


manyHelp : Parser a -> List a -> Parser (Step (List a) (List a))
manyHelp p vs =
    oneOf
        [ succeed (\v -> Loop (v :: vs))
            |= p
            |. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse vs))
        ]


depth : Tree a -> Int
depth t =
    let
        c =
            Tree.children t
    in
    if c == [] then
        0

    else
        1 + maxiumumPositiveInteger (List.map depth c)


maxiumumPositiveInteger : List Int -> Int
maxiumumPositiveInteger ints =
    List.foldl (\i acc -> max i acc) 0 ints


size : Tree a -> Int
size t =
    let
        c =
            Tree.children t
    in
    if c == [] then
        1

    else
        1 + List.sum (List.map size c)


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


getMicroLaTeXItem : String -> String -> Maybe String
getMicroLaTeXItem key str =
    case Parser.run (macroValParser key) str of
        Ok val ->
            Just val

        Err _ ->
            Nothing


{-|

    > getBracketedItems "ho ho ho! [foo] [bar]"
    ["foo","bar"] : List String

-}
getBracketedItems : String -> List String
getBracketedItems str =
    case Parser.run (many bracketedItemParser) str of
        Ok val ->
            val

        Err _ ->
            []


getBracketedItem : String -> Maybe String
getBracketedItem str =
    case Parser.run bracketedItemParser str of
        Ok val ->
            Just val

        Err _ ->
            Nothing


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


bracketedItemParser : Parser String
bracketedItemParser =
    (Parser.succeed String.slice
        |. Parser.chompUntil "["
        |. Parser.symbol "["
        |. Parser.spaces
        |= Parser.getOffset
        |. Parser.chompUntil "]"
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
