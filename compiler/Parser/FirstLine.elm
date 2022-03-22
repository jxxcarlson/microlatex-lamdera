module Parser.FirstLine exposing (FirstLineClassification(..), classify)

import Parser exposing ((|.), (|=), Parser)
import Set


type FirstLineClassification
    = FBareMacro String
    | FMacro String (List String)
    | FMathBlock
    | FVerbatimBlock
    | FNothing


classifierParser : Parser FirstLineClassification
classifierParser =
    Parser.oneOf [ bareMacroParser, mathBlockDelimParser, verbatimBlockDelimParser ]


classify : String -> FirstLineClassification
classify str =
    let
        str_ =
            String.trimLeft str
    in
    case Parser.run classifierParser str_ of
        Ok classif ->
            classif

        Err _ ->
            FNothing


mathBlockDelimParser : Parser FirstLineClassification
mathBlockDelimParser =
    (Parser.succeed ()
        |. Parser.symbol "$$"
    )
        |> Parser.map (\_ -> FMathBlock)


verbatimBlockDelimParser : Parser FirstLineClassification
verbatimBlockDelimParser =
    (Parser.succeed ()
        |. Parser.symbol "```"
    )
        |> Parser.map (\_ -> FVerbatimBlock)


macroParser =
    (Parser.succeed String.slice
        |. Parser.spaces
        |. Parser.symbol "\\"
        |= Parser.getOffset
        |. Parser.chompUntil "{"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map FBareMacro


bareMacroParser =
    (Parser.succeed String.slice
        |. Parser.spaces
        |. Parser.symbol "\\"
        |= Parser.getOffset
        |. Parser.chompUntil "\n"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map FBareMacro



--bareMacroParser : Parser FirstLineClassification
--bareMacroParser =
--    Parser.variable
--        { start = \c -> c == '\\'
--        , inner = \c -> Char.isAlphaNum c
--        , reserved = Set.fromList []
--        }
--        |> Parser.map (String.dropLeft 1)
--        |> Parser.map FBareMacro
