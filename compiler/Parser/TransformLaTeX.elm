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
    { lineNumber : Int
    , indent : Int
    , input : List String
    , output : List String
    , blockNameStack : List String
    , previousLineIsEmpty : Bool
    }


transformToL0 : List String -> List String
transformToL0 strings =
    strings |> indentStrings |> transformToL0Aux


indentStrings : List String -> List String
indentStrings strings =
    let
        finalState =
            indentAux { lineNumber = -1, previousLineIsEmpty = True, indent = -1, input = strings, output = [], blockNameStack = [] }

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


popIf : String -> List String -> List String
popIf s1 list =
    case List.head list of
        Nothing ->
            list

        Just s2 ->
            if s1 == s2 then
                List.drop 1 list

            else
                list


indentAux : IndentationData -> IndentationData
indentAux ({ lineNumber, indent, input, output, blockNameStack, previousLineIsEmpty } as data) =
    case input of
        [] ->
            data

        first :: rest ->
            let
                ( newIndent, blockNameStack_, status ) =
                    case classify first of
                        -- \begin{blockName} found -- start a new block
                        CBeginBlock blockName ->
                            ( indent + 1, blockName :: blockNameStack, NoError ) |> reportState "(1)" lineNumber first

                        CMathBlockDelim ->
                            case List.head blockNameStack of
                                Nothing ->
                                    ( indent + 1, "$$" :: blockNameStack, NoError ) |> reportState "(2a)" lineNumber first

                                Just "$$" ->
                                    -- the current "$$" matches the one on top of the stack
                                    ( indent - 1, List.drop 1 blockNameStack, NoError ) |> reportState "(2b)" lineNumber first

                                Just _ ->
                                    ( indent + 1, "$$" :: blockNameStack, NoError ) |> reportState "(2c)" lineNumber first

                        CVerbatimBlockDelim ->
                            case List.head blockNameStack of
                                Nothing ->
                                    ( indent + 1, "```" :: blockNameStack, NoError ) |> reportState "(3a)" lineNumber first

                                Just "```" ->
                                    -- the current "```" matches the one on top of the stack
                                    ( indent - 1, List.drop 1 blockNameStack, NoError ) |> reportState "(3b)" lineNumber first

                                Just _ ->
                                    ( indent + 1, "```" :: blockNameStack, NoError ) |> reportState "(3c)" lineNumber first

                        CEndBlock blockName ->
                            -- \end{blockName} found -- end the block
                            case List.head (popIf "para" blockNameStack) of
                                -- the blockName stack is empty, so there is no mach for blockName,
                                -- and so there is an error
                                Nothing ->
                                    ( indent - 1, [], MissingEndBlock blockName ) |> reportState "(4a)" lineNumber first

                                Just blockNameTop ->
                                    -- blockName matches the top of the blockNameStack, so pop the stack
                                    if blockName == blockNameTop then
                                        ( indent - 1, List.drop 1 (popIf "para" blockNameStack), NoError ) |> reportState "(4b)" lineNumber first
                                        -- no match of blockName at top of stack: error

                                    else
                                        ( indent - 1, blockNameStack, MisMatchedEndBlock blockName blockNameTop ) |> reportState "(4c)" lineNumber first

                        CPlainText ->
                            if previousLineIsEmpty then
                                ( indent + 1, "para" :: blockNameStack, NoError ) |> reportState "(5a)" lineNumber first

                            else
                                case List.head blockNameStack of
                                    Just "para" ->
                                        -- inside existing paragraph
                                        ( indent, blockNameStack, NoError ) |> reportState "(5b)" lineNumber first

                                    Just _ ->
                                        -- inside existing block, so do nothing
                                        ( indent, blockNameStack, NoError ) |> reportState "(5c)" lineNumber first

                                    Nothing ->
                                        -- no blocks on stack, so create one
                                        ( indent, "para" :: blockNameStack, NoError ) |> reportState "(5d)" lineNumber first

                        CEmpty ->
                            case List.head blockNameStack of
                                Nothing ->
                                    ( indent, blockNameStack, NoError ) |> reportState "(6a)" lineNumber first

                                Just "para" ->
                                    let
                                        newIdent =
                                            if indent == 0 then
                                                0

                                            else
                                                indent - 1
                                    in
                                    ( newIdent, List.drop 1 blockNameStack, NoError ) |> reportState "(6b)" lineNumber first

                                Just _ ->
                                    ( indent, blockNameStack, NoError ) |> reportState "(6c)" lineNumber first

                newOutput =
                    if isEnd first then
                        indentString indent first :: output

                    else
                        indentString newIndent first :: output
            in
            case status of
                NoError ->
                    indentAux { data | previousLineIsEmpty = False, lineNumber = lineNumber + 1, output = newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }

                PreviousLineEmpty ->
                    indentAux { data | previousLineIsEmpty = True, lineNumber = lineNumber + 1, output = newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }

                MissingEndBlock blockName ->
                    indentAux { data | previousLineIsEmpty = False, lineNumber = lineNumber + 1, output = ("missing end block: " ++ blockName) :: newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }

                MisMatchedEndBlock b1 b2 ->
                    indentAux { data | previousLineIsEmpty = False, lineNumber = lineNumber + 1, output = ("mismatched end blocks: " ++ b1 ++ ", " ++ b2) :: newOutput, input = rest, indent = newIndent, blockNameStack = blockNameStack_ }


reportState label lineNumber_ first_ =
    Debug.log (String.fromInt lineNumber_ ++ " " ++ label ++ " " ++ first_ |> (\s -> Tools.cyan s 16))


type Status
    = NoError
    | PreviousLineEmpty
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
