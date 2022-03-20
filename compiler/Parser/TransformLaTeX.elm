module Parser.TransformLaTeX exposing
    ( classify
    , indentStrings
    , transformToL0
    , transformToL0Aux
    )

import Parser exposing ((|.), (|=), Parser)
import Parser.MathMacro exposing (MathExpression(..))
import Tools



-- TRANSFORMS


type alias IndentationData =
    { lineNumber : Int, indent : Int, input : List String, output : List String, blockNameStack : List String }


transformToL0 : List String -> List String
transformToL0 strings =
    strings |> indentStrings |> transformToL0Aux


indentStrings : List String -> List String
indentStrings strings =
    let
        finalState =
            indentAux { lineNumber = -1, indent = -1, input = strings, output = [], blockNameStack = [] }

        errorList =
            List.map (\s -> "unmatched block " ++ s) finalState.blockNameStack

        output =
            if List.isEmpty errorList then
                finalState.output |> List.reverse

            else
                errorList ++ finalState.output |> List.reverse
    in
    --indentAux { lineNumber = -1, indent = -1, input = strings, output = [], blockNameStack = [] } |> .output |> List.reverse
    output


indentAux : IndentationData -> IndentationData
indentAux ({ lineNumber, indent, input, output, blockNameStack } as data) =
    case input of
        [] ->
            data

        first :: rest ->
            let
                ( newIndent, blockNameStack_, error ) =
                    case classify first of
                        -- \begin{blockName} found -- start a new block
                        CBeginBlock blockName ->
                            ( indent + 1, blockName :: blockNameStack, NoError ) |> reportState "(1)" lineNumber first

                        CMathBlockDelim ->
                            case List.head blockNameStack of
                                Nothing ->
                                    ( indent + 1, "$$" :: blockNameStack, NoError ) |> reportState "(1b)" lineNumber first

                                Just "$$" ->
                                    -- the current "$$" matches the one on top of the stack
                                    ( indent - 1, List.drop 1 blockNameStack, MapToEmpty ) |> reportState "(1c)" lineNumber first

                                Just _ ->
                                    ( indent + 1, "$$" :: blockNameStack, NoError ) |> reportState "(1d)" lineNumber first

                        CVerbatimBlockDelim ->
                            case List.head blockNameStack of
                                Nothing ->
                                    ( indent + 1, "```" :: blockNameStack, NoError ) |> reportState "(1b)" lineNumber first

                                Just "```" ->
                                    -- the current "```" matches the one on top of the stack
                                    ( indent - 1, List.drop 1 blockNameStack, MapToEmpty ) |> reportState "(1c)" lineNumber first

                                Just _ ->
                                    ( indent + 1, "```" :: blockNameStack, NoError ) |> reportState "(1d)" lineNumber first

                        CEndBlock blockName ->
                            -- \end{blockName} found -- end the block
                            case List.head blockNameStack of
                                -- the blockName stack is empty, so there is no mach for blockName,
                                -- and so there is an error
                                Nothing ->
                                    ( indent - 1, [], MissingEndBlock blockName ) |> reportState "(2)" lineNumber first

                                Just blockNameTop ->
                                    -- blockName matches the top of the blockNameStack, so pop the stack
                                    if blockName == blockNameTop then
                                        ( indent - 1, List.drop 1 blockNameStack, NoError ) |> reportState "(3)" lineNumber first
                                        -- no match of blockName at top of stack: error

                                    else
                                        ( indent - 1, blockNameStack, MisMatchedEndBlock blockName blockNameTop ) |> reportState "(4)" lineNumber first

                        CPlainText ->
                            case ( first, blockNameStack ) of
                                ( "", blockName :: rest_ ) ->
                                    -- ( indent, rest_, MissingEndBlock blockName )
                                    ( indent, blockNameStack, NoError ) |> reportState "(5)" lineNumber first

                                _ ->
                                    ( indent, blockNameStack, NoError ) |> reportState "(6)" lineNumber first

                        CEmpty ->
                            ( indent, blockNameStack, NoError ) |> reportState "(7)" lineNumber first

                newOutput =
                    if isEnd first then
                        indentString indent first :: output

                    else
                        indentString newIndent first :: output
            in
            case error of
                NoError ->
                    indentAux { data | lineNumber = lineNumber + 1, output = newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }

                MapToEmpty ->
                    indentAux { data | lineNumber = lineNumber + 1, output = "" :: output, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }

                MissingEndBlock blockName ->
                    indentAux { data | lineNumber = lineNumber + 1, output = ("missing end block: " ++ blockName) :: newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }

                MisMatchedEndBlock b1 b2 ->
                    indentAux { data | lineNumber = lineNumber + 1, output = ("mismatched end blocks: " ++ b1 ++ ", " ++ b2) :: newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }


reportState label lineNumber_ first_ =
    Debug.log (String.fromInt lineNumber_ ++ " " ++ label ++ " " ++ first_ |> (\s -> Tools.cyan s 16))


type Status
    = NoError
    | MapToEmpty
    | MissingEndBlock String
    | MisMatchedEndBlock String String


indentString : Int -> String -> String
indentString k str =
    String.repeat (2 * k) " " ++ str


verbatimBlockNames =
    [ "math", "equation", "aligned", "code" ]


transformBlockHeader : String -> String -> String
transformBlockHeader blockName str =
    if List.member blockName verbatimBlockNames then
        String.replace ("\\begin{" ++ blockName ++ "}") ("|| " ++ blockName) str

    else
        String.replace ("\\begin{" ++ blockName ++ "}") ("| " ++ blockName) str


transformToL0Aux : List String -> List String
transformToL0Aux strings =
    let
        mapper str =
            let
                bareString =
                    String.trimLeft str
            in
            if isBegin bareString then
                case Parser.MathMacro.parseOne bareString of
                    Just (Macro "begin" [ MathList [ MathText blockName ] ]) ->
                        transformBlockHeader blockName str
                            -- TODO: Better code here
                            |> String.replace "[" " "
                            |> String.replace "]" " "

                    _ ->
                        ""

            else if isEnd bareString then
                ""

            else
                str
    in
    strings |> List.map mapper


type Classification
    = CBeginBlock String
    | CEndBlock String
    | CMathBlockDelim
    | CVerbatimBlockDelim
    | CPlainText
    | CEmpty


classifierParser : Parser Classification
classifierParser =
    Parser.oneOf [ beginBlockParser, endBlockParser, mathBlockDelimParser, verbatimBlockDelimParser ]


classify : String -> Classification
classify str =
    let
        str_ =
            String.trimLeft str
    in
    case Parser.run classifierParser str_ of
        Ok classif ->
            classif

        Err _ ->
            if str == "" then
                CEmpty

            else
                CPlainText


mathBlockDelimParser : Parser Classification
mathBlockDelimParser =
    (Parser.succeed ()
        |. Parser.symbol "$$"
    )
        |> Parser.map (\_ -> CMathBlockDelim)


verbatimBlockDelimParser : Parser Classification
verbatimBlockDelimParser =
    (Parser.succeed ()
        |. Parser.symbol "```"
    )
        |> Parser.map (\_ -> CVerbatimBlockDelim)


beginBlockParser =
    (Parser.succeed String.slice
        |. Parser.symbol "\\begin{"
        |= Parser.getOffset
        |. Parser.chompUntil "}"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map CBeginBlock


endBlockParser =
    (Parser.succeed String.slice
        |. Parser.symbol "\\end{"
        |= Parser.getOffset
        |. Parser.chompUntil "}"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map CEndBlock


blockBegin : String -> Maybe String
blockBegin str =
    if str == "$$" then
        Just "$$"

    else
        case Parser.MathMacro.parseOne str of
            Just (Macro "begin" [ MathList [ MathText blockName ] ]) ->
                Just blockName

            _ ->
                Nothing


blockEnd : String -> Maybe String
blockEnd str =
    if str == "$$" then
        Just "$$"

    else
        case Parser.MathMacro.parseOne str of
            Just (Macro "end" [ MathList [ MathText blockName ] ]) ->
                Just blockName

            _ ->
                Nothing


isBegin : String -> Bool
isBegin str =
    String.left 6 (String.trimLeft str) == "\\begin"


isEnd : String -> Bool
isEnd str =
    String.left 4 (String.trimLeft str) == "\\end"
