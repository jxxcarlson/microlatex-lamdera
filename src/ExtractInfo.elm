module ExtractInfo exposing (makeFolder, parseBlockName, parseBlockNameWithArgs, parseInfo)

import Dict exposing (Dict)
import Document exposing (Document)
import Parser exposing ((|.), (|=), Parser, Step(..), loop)
import Parser.Language
import Time


makeFolder : Time.Posix -> String -> String -> String -> Document
makeFolder time username title tag =
    let
        content =
            [ "| title", title, "", "[tags :folder]", "", "| type folder get:" ++ tag ++ " ;", "" ] |> String.join "\n"

        empty =
            Document.empty

        slug =
            username ++ ":folder-" ++ tag
    in
    { empty
        | id = slug
        , title = title
        , author = Just username
        , language = Parser.Language.L0Lang
        , content = content
        , created = time
        , modified = time
    }


{-|

     > parseInfo "type" "| type folder a:1 b:2"
     Just ("folder",Dict.fromList [("a","1"),("b","2")])

-}
parseInfo : String -> String -> Maybe ( String, Dict String String )
parseInfo label str =
    case Parser.run (infoParser label) str of
        Ok data ->
            Just data

        Err _ ->
            Nothing


{-|

    > parseBlockName "collection" "ddd\\n| collection foo 77\\ndkfdj"
    > Just "collection" : Maybe String

-}
parseBlockName : String -> String -> Maybe String
parseBlockName name str =
    case Parser.run (blockNameParser name) str of
        Ok data ->
            Just data

        Err _ ->
            Nothing


{-|

    > parseBlockNameWithArgs "collection" "ddd\n| collection foo 77\ndkfdj"
     Just ("collection",["foo","77"])

-}
parseBlockNameWithArgs : String -> String -> Maybe ( String, List String )
parseBlockNameWithArgs name str =
    case Parser.run (blockNameWithArgsParser name) str of
        Ok data ->
            Just data

        Err _ ->
            Nothing


infoParser : String -> Parser ( String, Dict String String )
infoParser label =
    first (infoParser_ label) (Parser.symbol "\n")


infoParser_ : String -> Parser ( String, Dict String String )
infoParser_ label =
    typeParser label
        |> Parser.andThen
            (\name ->
                dictParser
                    |> Parser.map (\dict -> ( name, dict ))
            )


first : Parser a -> Parser b -> Parser a
first p q =
    p |> Parser.andThen (\x -> q |> Parser.map (\_ -> x))


second : Parser a -> Parser b -> Parser b
second p q =
    p |> Parser.andThen (\_ -> q)


typeParser : String -> Parser String
typeParser label =
    let
        target =
            "| " ++ label ++ " "
    in
    Parser.succeed (\labelStart labelEnd source -> String.slice labelStart labelEnd source)
        |. Parser.chompUntil target
        |. Parser.symbol target
        |= Parser.getOffset
        |. Parser.chompUntilEndOr " "
        |= Parser.getOffset
        |= Parser.getSource


blockNameWithArgsParser : String -> Parser ( String, List String )
blockNameWithArgsParser label =
    blockNameParser label |> Parser.andThen (\name -> lineParser |> Parser.map (\line -> ( name, line |> String.trim |> String.words )))


blockNameParser : String -> Parser String
blockNameParser label =
    let
        target =
            "| " ++ label
    in
    Parser.succeed (\labelStart labelEnd source -> String.slice (labelStart + 2) labelEnd source)
        |. Parser.chompUntil target
        |= Parser.getOffset
        |. Parser.symbol target
        |= Parser.getOffset
        |= Parser.getSource


kvParser : Parser ( String, String )
kvParser =
    Parser.succeed
        (\keyStart keyEnd valueStart valueEnd source ->
            ( String.slice keyStart keyEnd source, String.slice valueStart valueEnd source )
        )
        |. Parser.spaces
        |= Parser.getOffset
        |. Parser.chompUntil ":"
        |= Parser.getOffset
        |. Parser.symbol ":"
        |= Parser.getOffset
        |. Parser.chompUntil " "
        |= Parser.getOffset
        |= Parser.getSource


lineParser : Parser String
lineParser =
    Parser.succeed (\start end source -> String.slice start end source)
        |= Parser.getOffset
        |. Parser.chompUntilEndOr "\n"
        |= Parser.getOffset
        |= Parser.getSource


dictParser : Parser (Dict String String)
dictParser =
    first (many kvParser) (Parser.symbol ";") |> Parser.map Dict.fromList


{-| Apply a parser zero or more times and return a list of the results.
-}
many : Parser a -> Parser (List a)
many p =
    loop [] (manyHelp p)


manyHelp : Parser a -> List a -> Parser (Step (List a) (List a))
manyHelp p vs =
    Parser.oneOf
        [ Parser.succeed (\v -> Loop (v :: vs))
            |= p
            |. Parser.spaces
        , Parser.succeed ()
            |> Parser.map (\_ -> Done (List.reverse vs))
        ]
