module ExtractInfo exposing (parseInfo)

import Dict exposing (Dict)
import Parser exposing ((|.), (|=), Parser, Step(..), loop)


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


infoParser : String -> Parser ( String, Dict String String )
infoParser label =
    typeParser label |> Parser.andThen (\name -> dictParser |> Parser.map (\dict -> ( name, dict )))


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
        |. Parser.chompUntilEndOr " "
        |= Parser.getOffset
        |= Parser.getSource


dictParser : Parser (Dict String String)
dictParser =
    many kvParser |> Parser.map Dict.fromList


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
