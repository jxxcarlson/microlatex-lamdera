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
    | CMoveCursor Int
    | CDelete Int Int
    | CNoOp


toString : Int -> Command -> String
toString counter command =
    encode counter command |> E.encode 2


toCommand : NetworkModel.EditEvent -> Command
toCommand event =
    case event.operation of
        OT.Insert cursor str ->
            CInsert cursor str

        OT.Delete cursor k ->
            CDelete cursor k

        OT.MoveCursor cursor ->
            CMoveCursor cursor

        _ ->
            CNoOp


encode : Int -> Command -> E.Value
encode counter command =
    case command of
        CInsert cursor str ->
            E.object [ ( "op", E.string "insert" ), ( "cursor", E.int cursor ), ( "strval", E.string str ), ( "counter", E.int counter ) ]

        CMoveCursor cursor ->
            -- cursor is the new absolute value of the cursor
            E.object [ ( "op", E.string "movecursor" ), ( "cursor", E.int cursor ), ( "intval", E.int 0 ), ( "counter", E.int counter ) ]

        CDelete cursor k ->
            E.object [ ( "op", E.string "delete" ), ( "cursor", E.int cursor ), ( "intval", E.int k ), ( "counter", E.int counter ) ]

        CNoOp ->
            E.object [ ( "op", E.string "noop" ), ( "cursor", E.int 0 ), ( "intval", E.int 0 ), ( "counter", E.int counter ) ]


parseCommand : String -> Command
parseCommand str =
    case run commandParser str of
        Ok command ->
            command

        Err _ ->
            CNoOp


commandParser =
    oneOf [ insertionParser, moveParser, deleteParser ]


insertionParser : Parser Command
insertionParser =
    succeed (\c str -> CInsert c str)
        |. symbol "insert"
        |. spaces
        |= int
        |. spaces
        |= wordParser


moveParser : Parser Command
moveParser =
    succeed (\c -> CMoveCursor c)
        |. symbol "move"
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
