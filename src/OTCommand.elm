module OTCommand exposing (Command, parseCommand, toString)

-- insert CURSOR foo
-- skip CURSOR K
-- delete CURSOR k

import Json.Encode as E
import Parser exposing (..)


toString : Int -> Maybe Command -> String
toString counter command =
    encodeCommand counter command |> E.encode 2


encodeCommand : Int -> Maybe Command -> E.Value
encodeCommand counter mCommand =
    case mCommand of
        Nothing ->
            E.object [ ( "no Op", E.string "NoOp" ) ]

        Just command ->
            case command of
                CInsert cursor str ->
                    E.object [ ( "op", E.string "insert" ), ( "cursor", E.int cursor ), ( "strval", E.string str ), ( "counter", E.int counter ) ]

                CSkip cursor skip ->
                    E.object [ ( "op", E.string "skip" ), ( "cursor", E.int cursor ), ( "intval", E.int skip ), ( "counter", E.int counter ) ]

                CDelete cursor k ->
                    E.object [ ( "op", E.string "delete" ), ( "cursor", E.int cursor ), ( "intval", E.int k ), ( "counter", E.int counter ) ]


type Command
    = CInsert Int String
    | CSkip Int Int
    | CDelete Int Int


parseCommand : String -> Maybe Command
parseCommand str =
    case run commandParser str of
        Ok command ->
            Just command

        Err _ ->
            Nothing


commandParser =
    oneOf [ insertionParser, skipParser, deleteParser ]


insertionParser : Parser Command
insertionParser =
    succeed (\c str -> CInsert c str)
        |. symbol "insert"
        |. spaces
        |= int
        |. spaces
        |= wordParser


skipParser : Parser Command
skipParser =
    succeed (\c k -> CSkip c k)
        |. symbol "skip"
        |. spaces
        |= int
        |. spaces
        |= int


deleteParser : Parser Command
deleteParser =
    succeed (\c k -> CDelete c k)
        |. symbol "delete"
        |. spaces
        |= int
        |. spaces
        |= int


wordParser : Parser String
wordParser =
    getChompedString <|
        succeed ()
            |. chompWhile (\c -> Char.isAlphaNum c)
