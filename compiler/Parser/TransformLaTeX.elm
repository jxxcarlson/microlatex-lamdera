module Parser.TransformLaTeX exposing
    ( err
    , indentStrings
    , transformToL0
    , transformToL0Aux
    )

import Parser.Classify exposing (Classification(..), classify)
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
    , hasError : Bool
    , blockStatus : BlockStatus
    }


type BlockStatus
    = BlockStarted String
    | PassThroughBlock
    | NormalBlock
    | OutsideBlock


err9 =
    """
\\begin{theorem}
abc
\\end{theorem}

\\begin{theorem}
  abc
  
  def
\\end{theorem}

\\begin{theorem}
  HIJ

  \\begin{foo}
  HO HO HO
  \\end{foo}

  KLM
\\end{theorem}

\\begin{theorem}
RA RA RA!
\\end{theorem}
"""


err =
    """
\\begin{theorem}
There are infinitely many primes.
\\end{theorem}
"""


err1 =
    """\\begin{theorem}
There are infinitely many primes.

This is a test
"""


transformToL0 : List String -> List String
transformToL0 strings =
    strings |> Debug.log "RAW" |> indentStrings |> Debug.log "INDENTED" |> transformToL0Aux |> Debug.log "TRANSFORMED"


missingEndBlockMessge : String -> String
missingEndBlockMessge blockName =
    "\\vskip{11}\\red{^^^^^^ missing end tag: " ++ blockName ++ "}\\vskip{11}"


mismatchedEndBlockMessge : String -> String -> String
mismatchedEndBlockMessge blockName1 blockName2 =
    "\\vskip{11}\\red{^^^^^^ mismatched end tags: " ++ blockName1 ++ " -> " ++ blockName2 ++ "}\\vskip{11}"


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
                { xIndent, xBlockStack, xStatus } =
                    case classify first of
                        -- \begin{blockName} found -- start a new block
                        CBeginBlock blockName ->
                            { xIndent = indent + 1, xBlockStack = blockName :: blockNameStack, xStatus = NoError } |> reportState "(1)" lineNumber first

                        CMathBlockDelim ->
                            case List.head blockNameStack of
                                Nothing ->
                                    { xIndent = indent + 1, xBlockStack = "$$" :: blockNameStack, xStatus = NoError } |> reportState "(2a)" lineNumber first

                                Just "$$" ->
                                    -- the current "$$" matches the one on top of the stack
                                    { xIndent = indent - 1, xBlockStack = List.drop 1 blockNameStack, xStatus = NoError } |> reportState "(2b)" lineNumber first

                                Just _ ->
                                    { xIndent = indent + 1, xBlockStack = "$$" :: blockNameStack, xStatus = NoError } |> reportState "(2c)" lineNumber first

                        CVerbatimBlockDelim ->
                            case List.head blockNameStack of
                                Nothing ->
                                    { xIndent = indent + 1, xBlockStack = "```" :: blockNameStack, xStatus = NoError } |> reportState "(3a)" lineNumber first

                                Just "```" ->
                                    -- the current "```" matches the one on top of the stack
                                    { xIndent = indent - 1, xBlockStack = List.drop 1 blockNameStack, xStatus = NoError } |> reportState "(3b)" lineNumber first

                                Just _ ->
                                    { xIndent = indent + 1, xBlockStack = "```" :: blockNameStack, xStatus = NoError } |> reportState "(3c)" lineNumber first

                        CEndBlock blockName ->
                            -- \end{blockName} found -- end the block
                            case List.head (popIf "para" blockNameStack) of
                                -- the blockName stack is empty, so there is no mach for blockName,
                                -- and so there is an error
                                Nothing ->
                                    { xIndent = indent - 1, xBlockStack = [], xStatus = MissingEndBlock blockName } |> reportState "(4a)" lineNumber first

                                Just blockNameTop ->
                                    -- blockName matches the top of the blockNameStack, so pop the stack
                                    if blockName == blockNameTop then
                                        -- TODO: was messed up
                                        { xIndent = indent - 1, xBlockStack = List.drop 1 blockNameStack, xStatus = NoError } |> reportState "(4b)" lineNumber first

                                    else
                                        { xIndent = indent - 1, xBlockStack = blockNameStack, xStatus = MisMatchedEndBlock blockName blockNameTop } |> reportState "(4c)" lineNumber first

                        CPlainText ->
                            if previousLineIsEmpty then
                                { xIndent = indent + 1, xBlockStack = "para" :: blockNameStack, xStatus = NoError } |> reportState "(5a)" lineNumber first

                            else
                                case List.head blockNameStack of
                                    Just "para" ->
                                        -- inside existing paragraph
                                        { xIndent = indent, xBlockStack = blockNameStack, xStatus = NoError } |> reportState "(5b)" lineNumber first

                                    Just _ ->
                                        -- inside existing block, so do nothing
                                        { xIndent = indent, xBlockStack = blockNameStack, xStatus = NoError } |> reportState "(5c)" lineNumber first

                                    Nothing ->
                                        -- no blocks on stack, so create one
                                        { xIndent = indent, xBlockStack = "para" :: blockNameStack, xStatus = NoError } |> reportState "(5d)" lineNumber first

                        CEmpty ->
                            case List.head blockNameStack of
                                Nothing ->
                                    { xIndent = indent, xBlockStack = blockNameStack, xStatus = NoError } |> reportState "(6a)" lineNumber first

                                Just "para" ->
                                    let
                                        newIdent =
                                            if indent == 0 then
                                                0

                                            else
                                                indent - 1
                                    in
                                    { xIndent = newIdent, xBlockStack = List.drop 1 blockNameStack, xStatus = NoError } |> reportState "(6b)" lineNumber first

                                Just blockName ->
                                    { xIndent = indent, xBlockStack = blockNameStack, xStatus = MissingEndBlock blockName } |> reportState "(6c)" lineNumber first
            in
            case xStatus of
                NoError ->
                    indentAux { data | previousLineIsEmpty = False, lineNumber = lineNumber + 1, input = rest, indent = xIndent, blockNameStack = xBlockStack, output = first :: output }

                PreviousLineEmpty ->
                    indentAux { data | previousLineIsEmpty = True, lineNumber = lineNumber + 1, input = rest, indent = xIndent, blockNameStack = xBlockStack }

                MissingEndBlock blockName ->
                    indentAux { data | hasError = True, blockNameStack = List.drop 1 blockNameStack, previousLineIsEmpty = False, lineNumber = lineNumber + 1, output = endBlockWithName blockName :: missingEndBlockMessge blockName :: output, input = rest, indent = xIndent }

                MisMatchedEndBlock b1 b2 ->
                    indentAux { data | hasError = True, previousLineIsEmpty = False, lineNumber = lineNumber + 1, output = endBlockWithName b1 :: mismatchedEndBlockMessge b1 b2 :: List.drop 1 output, input = rest, indent = xIndent, blockNameStack = List.drop 1 xBlockStack }


endBlockWithName name =
    "\\end{" ++ name ++ "}"


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
