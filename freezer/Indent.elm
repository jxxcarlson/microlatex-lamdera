module MicroLaTeX.Parser.Indent exposing (..)

import Dict exposing (Dict)
import Parser.Classify exposing (Classification(..), classify)
import Parser.MathMacro exposing (MathExpression(..))
import Parser.TextMacro exposing (MyMacro(..))


type alias IndentationData =
    { lineNumber : Int
    , indent : Int
    , input : List String
    , output : List String
    , blockNameStack : List String
    , previousLineIsEmpty : Bool
    , hasError : Bool
    , blockStatus : BlockStatus
    }


type BlockStatus
    = BlockStarted String
    | PassThroughBlock
    | NormalBlock
    | OutsideBlock


type Status
    = NoError
    | PreviousLineEmpty
    | MissingEndBlock String
    | MisMatchedEndBlock String String


indentStrings : List String -> List String
indentStrings strings =
    let
        finalState =
            indentAux { blockStatus = OutsideBlock, hasError = False, lineNumber = -1, previousLineIsEmpty = True, indent = -1, input = strings, output = [], blockNameStack = [] }

        errorList =
            List.map (\s -> missingEndBlockMessge s) finalState.blockNameStack

        output =
            if List.isEmpty errorList then
                finalState.output |> List.reverse

            else if finalState.hasError then
                finalState.output |> List.reverse

            else
                errorList ++ finalState.output |> List.reverse
    in
    output


{-| State machine to indent lines in preparation for transformation to L0
-}
indentAux : IndentationData -> IndentationData
indentAux ({ blockStatus, lineNumber, indent, input, output, blockNameStack, previousLineIsEmpty } as data) =
    case input of
        [] ->
            data

        first :: rest ->
            let
                { xBlockStatus, xIndent, xBlockStack, xStatus } =
                    case classify first of
                        -- \begin{blockName} found -- start a new block
                        CBeginBlock blockName ->
                            { xBlockStatus = BlockStarted blockName, xIndent = indent + 1, xBlockStack = blockName :: blockNameStack, xStatus = NoError } |> reportState "(1)" lineNumber first

                        CMathBlockDelim ->
                            case List.head blockNameStack of
                                Nothing ->
                                    { xBlockStatus = blockStatus, xIndent = indent + 1, xBlockStack = "$$" :: blockNameStack, xStatus = NoError } |> reportState "(2a)" lineNumber first

                                Just "$$" ->
                                    -- the current "$$" matches the one on top of the stack
                                    { xBlockStatus = blockStatus, xIndent = indent - 1, xBlockStack = List.drop 1 blockNameStack, xStatus = NoError } |> reportState "(2b)" lineNumber first

                                Just _ ->
                                    { xBlockStatus = blockStatus, xIndent = indent + 1, xBlockStack = "$$" :: blockNameStack, xStatus = NoError } |> reportState "(2c)" lineNumber first

                        CVerbatimBlockDelim ->
                            case List.head blockNameStack of
                                Nothing ->
                                    { xBlockStatus = blockStatus, xIndent = indent + 1, xBlockStack = "```" :: blockNameStack, xStatus = NoError } |> reportState "(3a)" lineNumber first

                                Just "```" ->
                                    -- the current "```" matches the one on top of the stack
                                    { xBlockStatus = blockStatus, xIndent = indent - 1, xBlockStack = List.drop 1 blockNameStack, xStatus = NoError } |> reportState "(3b)" lineNumber first

                                Just _ ->
                                    { xBlockStatus = blockStatus, xIndent = indent + 1, xBlockStack = "```" :: blockNameStack, xStatus = NoError } |> reportState "(3c)" lineNumber first

                        CEndBlock blockName ->
                            -- \end{blockName} found -- end the block
                            case List.head (popIf "para" blockNameStack) of
                                -- the blockName stack is empty, so there is no mach for blockName,
                                -- and so there is an error
                                Nothing ->
                                    { xBlockStatus = blockStatus, xIndent = indent - 1, xBlockStack = [], xStatus = MissingEndBlock blockName } |> reportState "(4a)" lineNumber first

                                Just blockNameTop ->
                                    -- blockName matches the top of the blockNameStack, so pop the stack
                                    if blockName == blockNameTop then
                                        -- TODO: was messed up
                                        { xBlockStatus = blockStatus, xIndent = indent - 1, xBlockStack = List.drop 1 blockNameStack, xStatus = NoError } |> reportState "(4b)" lineNumber first

                                    else
                                        { xBlockStatus = blockStatus, xIndent = indent - 1, xBlockStack = blockNameStack, xStatus = MisMatchedEndBlock blockName blockNameTop } |> reportState "(4c)" lineNumber first

                        CPlainText ->
                            if previousLineIsEmpty then
                                if blockStatus == PassThroughBlock then
                                    { xBlockStatus = blockStatus, xIndent = indent, xBlockStack = "para" :: blockNameStack, xStatus = NoError } |> reportState "(5a)" lineNumber first

                                else
                                    { xBlockStatus = blockStatus, xIndent = indent + 1, xBlockStack = "para" :: blockNameStack, xStatus = NoError } |> reportState "(5a)" lineNumber first

                            else
                                case List.head blockNameStack of
                                    Just "para" ->
                                        -- inside existing paragraph
                                        { xBlockStatus = blockStatus, xIndent = indent, xBlockStack = blockNameStack, xStatus = NoError } |> reportState "(5b)" lineNumber first

                                    Just _ ->
                                        -- inside existing block, so do nothing
                                        let
                                            ( indent_, blockStat ) =
                                                if leadingSpaces first == 0 then
                                                    ( indent, NormalBlock )

                                                else
                                                    ( indent, PassThroughBlock )
                                        in
                                        { xBlockStatus = blockStat, xIndent = indent_, xBlockStack = blockNameStack, xStatus = NoError } |> reportState "(5c)" lineNumber first

                                    Nothing ->
                                        -- no blocks on stack, so create one
                                        if blockStatus == PassThroughBlock then
                                            { xBlockStatus = blockStatus, xIndent = indent, xBlockStack = blockNameStack, xStatus = NoError } |> reportState "(5d)" lineNumber first

                                        else
                                            { xBlockStatus = blockStatus, xIndent = indent, xBlockStack = "para" :: blockNameStack, xStatus = NoError } |> reportState "(5e)" lineNumber first

                        CEmpty ->
                            case List.head blockNameStack of
                                Nothing ->
                                    { xBlockStatus = OutsideBlock, xIndent = indent, xBlockStack = blockNameStack, xStatus = NoError } |> reportState "(6a)" lineNumber first

                                Just "para" ->
                                    let
                                        newIdent =
                                            if indent == 0 then
                                                0

                                            else
                                                indent - 1
                                    in
                                    { xBlockStatus = OutsideBlock, xIndent = newIdent, xBlockStack = List.drop 1 blockNameStack, xStatus = NoError } |> reportState "(6b)" lineNumber first

                                Just blockName ->
                                    { xBlockStatus = OutsideBlock, xIndent = indent, xBlockStack = blockNameStack, xStatus = MissingEndBlock blockName } |> reportState "(6c)" lineNumber first
            in
            case xStatus of
                NoError ->
                    let
                        firstUpdated =
                            if blockStatus == PassThroughBlock then
                                first

                            else
                                first
                    in
                    indentAux { data | blockStatus = xBlockStatus, previousLineIsEmpty = False, lineNumber = lineNumber + 1, input = rest, indent = xIndent, blockNameStack = xBlockStack, output = firstUpdated :: output }

                PreviousLineEmpty ->
                    indentAux { data | blockStatus = xBlockStatus, previousLineIsEmpty = True, lineNumber = lineNumber + 1, input = rest, indent = xIndent, blockNameStack = xBlockStack }

                MissingEndBlock blockName ->
                    indentAux { data | blockStatus = xBlockStatus, hasError = True, blockNameStack = List.drop 1 blockNameStack, previousLineIsEmpty = False, lineNumber = lineNumber + 1, output = endBlockWithName blockName :: missingEndBlockMessge blockName :: output, input = rest, indent = xIndent }

                MisMatchedEndBlock b1 b2 ->
                    indentAux { data | blockStatus = xBlockStatus, hasError = True, previousLineIsEmpty = False, lineNumber = lineNumber + 1, output = endBlockWithName b1 :: mismatchedEndBlockMessge b1 b2 :: List.drop 1 output, input = rest, indent = xIndent, blockNameStack = List.drop 1 xBlockStack }


leadingSpaces : String -> Int
leadingSpaces str =
    String.length str - String.length (String.trimLeft str)


endBlockWithName name =
    "\\end{" ++ name ++ "}"


reportState label lineNumber_ first_ =
    -- fakeDebugLog (String.fromInt lineNumber_ ++ " " ++ label ++ " " ++ first_ |> (\s -> Tools.cyan s 16))
    identity


missingEndBlockMessge : String -> String
missingEndBlockMessge blockName =
    "\\vskip{11}\\red{^^^^^^ missing end tag: " ++ blockName ++ "}\\vskip{11}"


mismatchedEndBlockMessge : String -> String -> String
mismatchedEndBlockMessge blockName1 blockName2 =
    "\\vskip{11}\\red{^^^^^^ mismatched end tags: " ++ blockName1 ++ " -> " ++ blockName2 ++ "}\\vskip{11}"


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


indentString : Int -> String -> String
indentString k str =
    String.repeat (2 * k) " " ++ str



--
--toL0Aux : List String -> List String
--toL0Aux strings =
--    strings |> List.map (mapper2 >> makeBlanksEmpty)
--
--
--mapper2 str =
--    let
--        bareString =
--            String.trimLeft str
--    in
--    if isBegin bareString then
--        case Parser.MathMacro.parseOne bareString of
--            Just (Macro "begin" [ MathList [ MathText blockName ] ]) ->
--                transformBlockHeader blockName str
--                    -- TODO: Better code here
--                    |> String.replace "[" " "
--                    |> String.replace "]" " "
--
--            _ ->
--                ""
--
--    else if isEnd bareString then
--        ""
--
--    else
--        let
--            trimmed =
--                String.trim str
--
--            numberOfLeadingBlanks =
--                String.length str - String.length trimmed
--
--            leadingBlanks =
--                String.repeat numberOfLeadingBlanks " "
--
--            ( name, args ) =
--                case Parser.TextMacro.get (String.trim trimmed) of
--                    Ok (Parser.TextMacro.MyMacro name_ args_) ->
--                        ( name_, args_ )
--
--                    Err error ->
--                        ( "(no-name)", [] )
--        in
--        case Dict.get name substitutions of
--            Just { prefix, arity } ->
--                case arity of
--                    Arity _ ->
--                        leadingBlanks ++ prefix ++ " " ++ name ++ " " ++ String.join " " args
--
--                    Grouped ->
--                        leadingBlanks ++ prefix ++ " " ++ name ++ " " ++ "grouped(" ++ String.join " " args ++ ")"
--
--            Nothing ->
--                str
