module CollaborativeEditing.OTCommand exposing (Command(..), parseCommand, toCommand, toString)

-- insert CURSOR foo
-- skip CURSOR K
-- delete CURSOR k

import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OT as OT
import Json.Encode as E
import Parser exposing (..)


type Command
    = CInsert Int String
    | CMoveCursor Int Int
    | CDelete Int Int
    | CNoOp Int


toString : Int -> Maybe Command -> String
toString counter command =
    encode counter command |> E.encode 2


toCommand : NetworkModel.EditEvent -> Maybe Command
toCommand event =
    case event.operations of
        (OT.Insert cursor str) :: [] ->
            Just (CInsert cursor str)

        (OT.Delete cursor k) :: [] ->
            Just (CDelete cursor k)

        _ ->
            Nothing


encode : Int -> Maybe Command -> E.Value
encode counter mCommand =
    case mCommand of
        Nothing ->
            E.object [ ( "no Op", E.string "NoOp" ) ]

        Just command ->
            case command of
                CInsert cursor str ->
                    E.object [ ( "op", E.string "insert" ), ( "cursor", E.int cursor ), ( "strval", E.string str ), ( "counter", E.int counter ) ]

                CMoveCursor cursor skip ->
                    -- cursor is the new absolute value of the cursor
                    E.object [ ( "op", E.string "movecursor" ), ( "cursor", E.int cursor ), ( "intval", E.int skip ), ( "counter", E.int counter ) ]

                CDelete cursor k ->
                    E.object [ ( "op", E.string "delete" ), ( "cursor", E.int cursor ), ( "intval", E.int k ), ( "counter", E.int counter ) ]

                CNoOp cursor ->
                    E.object [ ( "op", E.string "noop" ), ( "cursor", E.int cursor ), ( "intval", E.int 0 ), ( "counter", E.int counter ) ]


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
    succeed (\c k -> CMoveCursor c k)
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
