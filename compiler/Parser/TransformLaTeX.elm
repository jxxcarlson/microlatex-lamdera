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


err =
    """\\begin{theorem}
  There are infinitely many primes.
  
  \\begin{equation}
  \\int_0^1 x^n dx = \\frac{1}{n+1}
  \\end{equation}
  
  Isn't that nice??
  Yes?
  No?
\\end{theorem}
"""


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


err2 =
    """
\\begin{theorem}
  abc

  def
\\end{theorem}

"""


err1 =
    """\\begin{theorem}
There are infinitely many primes.

This is a test
"""


transformToL0 : List String -> List String
transformToL0 strings =
    strings |> indentStrings |> transformToL0Aux


missingEndBlockMessge : String -> String
missingEndBlockMessge blockName =
    "\\vskip{11}\\red{^^^^^^ missing end tag: " ++ blockName ++ "}\\vskip{11}"


mismatchedEndBlockMessge : String -> String -> String
mismatchedEndBlockMessge blockName1 blockName2 =
    "\\vskip{11}\\red{^^^^^^ mismatched end tags: " ++ blockName1 ++ " -> " ++ blockName2 ++ "}\\vskip{11}"


type BlockStatus
    = BlockStarted String
    | PassThroughBlock
    | NormalBlock
    | OutsideBlock


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
    --Debug.log (String.fromInt lineNumber_ ++ " " ++ label ++ " " ++ first_ |> (\s -> Tools.cyan s 16))
    identity


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
    strings |> List.map (mapper >> makeBlanksEmpty)


makeBlanksEmpty : String -> String
makeBlanksEmpty str =
    if String.trim str == "" then
        ""

    else
        str


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
