module MicroLaTeX.Parser.TransformLaTeX exposing
    ( indentStrings
    , toL0
    , toL0Aux
    , toL0Aux2
    , xx
    , xx2
    , xx3
    , xx4
    , xx5
    , xx6
    )

import Dict exposing (Dict)
import Parser.Classify exposing (Classification(..), classify)
import Parser.MathMacro exposing (MathExpression(..))
import Parser.TextMacro exposing (MyMacro(..))



--fakeDebugLog =
--    \str -> Debug.log str


fakeDebugLog =
    \str -> identity


xx =
    """
\\title{MicroLaTeX Test}

abc

def
"""


xx2 =
    """
\\begin{equation}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}
"""


xx3 =
    """
\\item
Foo bar
"""


xx4 =
    """
\\bibitem{AA}
Foo bar
"""


xx5 =
    """
$$
x^2
$$
"""



-- TO L0: ["\\title{MicroLaTeX Test}","","| theorem","  AAA","","  $$","  x^2","  $$","","  BBB","","",""]


xx6 =
    "\\begin{theorem}\n  AAA\n  \n  $$\n  x^2\n  $$\n  \n  BBB\n\\end{theorem}"



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


{-| Map a list of strings to from microLaTeX block format to L0 block format.
It seems that function 'indentStrings' is unnecessary.
TODO: test the foregoing.
TODO: at the moment, there is no error-handling. Think about this
-}
toL0 : List String -> List String
toL0 strings =
    -- strings |> indentStrings |> toL0Aux
    strings |> toL0Aux2


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


type Status
    = NoError
    | PreviousLineEmpty
    | MissingEndBlock String
    | MisMatchedEndBlock String String


indentString : Int -> String -> String
indentString k str =
    String.repeat (2 * k) " " ++ str


verbatimBlockNames =
    [ "math", "equation", "aligned", "code", "mathmacros", "verbatim", "$$" ]


type alias State =
    { status : LXStatus, input : List String, output : List String }


type LXStatus
    = InVerbatimBlock String
    | InOrdinaryBlock
    | LXNormal


toL0Aux2 : List String -> List String
toL0Aux2 list =
    loop { input = list, output = [], status = LXNormal } nextState |> List.reverse


type Step state a
    = Loop state
    | Done a


loop : state -> (state -> Step state a) -> a
loop s f =
    case f s of
        Loop s_ ->
            loop s_ f

        Done b ->
            b


nextState : State -> Step State (List String)
nextState state =
    case List.head state.input of
        Nothing ->
            Done state.output

        Just line ->
            let
                trimmedLine =
                    String.trimLeft line |> fakeDebugLog "TRIMMED"

                numberOfLeadingBlanks =
                    String.length line - String.length trimmedLine

                prefix =
                    String.left numberOfLeadingBlanks line
            in
            case Parser.TextMacro.get trimmedLine of
                Err _ ->
                    if trimmedLine == "$$" then
                        Loop (nextState2 line (MyMacro "$$" []) { state | input = List.drop 1 state.input }) |> fakeDebugLog "(0a)"

                    else
                        -- Just add the line to output
                        Loop { state | output = line :: state.output, input = List.drop 1 state.input } |> fakeDebugLog "(0b)"

                Ok myMacro ->
                    let
                        _ =
                            fakeDebugLog "(0!!)" myMacro
                    in
                    Loop (nextState2 line myMacro { state | input = List.drop 1 state.input })


nextState2 line (MyMacro name args) state =
    if name == "begin" && args == [ "code" ] then
        -- HANDLE CODE BLOCKS, BEGIN
        { state | output = "|| code" :: state.output, status = InVerbatimBlock "code" } |> fakeDebugLog "(1)"

    else if name == "end" && args == [ "code" ] then
        -- HANDLE CODE BLOCKS, END
        { state | output = "" :: state.output, status = LXNormal } |> fakeDebugLog "(2)"

    else if name == "$$" && state.status == LXNormal then
        -- HANDLE $$ BLOCK, BEGIN
        { state | output = "$$" :: state.output, status = InVerbatimBlock "$$" } |> fakeDebugLog "(3)"

    else if List.member name [ "$$" ] && state.status == InVerbatimBlock name then
        -- HANDLE $$ BLOCK, END
        { state | output = "" :: state.output, status = LXNormal } |> fakeDebugLog "(4)"

    else if state.status == InVerbatimBlock "```" then
        -- HANDLE ``` BLOCK, INTERIOR
        { state | output = line :: state.output } |> fakeDebugLog "(3.1)"

    else if name == "begin" && state.status == LXNormal then
        -- HANDLE ENVIRONMENT, BEGIN
        { state | output = transformHeader name args line :: state.output, status = InOrdinaryBlock } |> fakeDebugLog "(5)"

    else if name == "end" && state.status == InOrdinaryBlock then
        -- HANDLE ENVIRONMENT, END
        { state | output = "" :: state.output } |> fakeDebugLog "(6)"

    else if state.status == LXNormal && List.member name [ "item", "numbered", "bibref", "desc", "contents" ] then
        -- HANDLE \item, \bibref, etc
        { state | output = (String.replace ("\\" ++ name) ("| " ++ name) line |> fixArgs) :: state.output } |> fakeDebugLog "(7)"
        -- ??

    else if state.status == InOrdinaryBlock then
        if String.trimLeft line == "" then
            { state | output = "" :: state.output } |> fakeDebugLog "(8)"

        else
            { state | output = transformHeader name args line :: state.output } |> fakeDebugLog "(9)"

    else
        { state | output = line :: state.output } |> fakeDebugLog "(10)"


transformHeader : String -> List String -> String -> String
transformHeader name args str =
    let
        _ =
            fakeDebugLog "args" args
    in
    if name == "begin" then
        transformBegin args str

    else
        transformOther name args str


transformOther name args str =
    let
        _ =
            fakeDebugLog "name" name

        target =
            if name == "$$" then
                "$$"

            else
                "\\" ++ name

        _ =
            fakeDebugLog "str" str

        _ =
            fakeDebugLog "TARGET (1)" target
    in
    case Dict.get name substitutions of
        Nothing ->
            str |> fakeDebugLog "NOTHING"

        Just { prefix } ->
            String.replace target ("| " ++ name) str |> fixArgs |> fakeDebugLog "Transformed!! (2)"


fixArgs str =
    str |> String.replace "{" " " |> String.replace "}" " "


transformBegin args str =
    case List.head args of
        Nothing ->
            str

        Just environmentName ->
            let
                _ =
                    fakeDebugLog "environmentName" environmentName

                target =
                    "\\begin{" ++ environmentName ++ "}"

                _ =
                    fakeDebugLog "str" str

                _ =
                    fakeDebugLog "TARGET (2)" target
            in
            case Dict.get environmentName substitutions of
                Nothing ->
                    str |> fakeDebugLog "NOTHING"

                Just { prefix } ->
                    String.replace target (prefix ++ " " ++ environmentName) str |> fakeDebugLog "Transformed!!"


transformBlockHeader2 : String -> String -> String
transformBlockHeader2 blockName str =
    transformBlockHeader_ blockName str |> String.replace "[" " " |> String.replace "]" " "


transformBlockHeader_ : String -> String -> String
transformBlockHeader_ blockName str =
    let
        _ =
            fakeDebugLog "transformBlockHeader_, blockName" blockName
    in
    if List.member blockName verbatimBlockNames then
        String.replace ("\\begin{" ++ blockName ++ "}") ("|| " ++ blockName) str

    else
        String.replace ("\\begin{" ++ blockName ++ "}") ("| " ++ blockName) str


transformBlockHeader : String -> String -> String
transformBlockHeader blockName str =
    if List.member blockName verbatimBlockNames then
        String.replace ("\\begin{" ++ blockName ++ "}") ("|| " ++ blockName) str

    else
        String.replace ("\\begin{" ++ blockName ++ "}") ("| " ++ blockName) str


toL0Aux : List String -> List String
toL0Aux strings =
    strings |> List.map (mapper2 >> makeBlanksEmpty)


mapper2 str =
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
        let
            trimmed =
                String.trim str

            numberOfLeadingBlanks =
                String.length str - String.length trimmed

            leadingBlanks =
                String.repeat numberOfLeadingBlanks " "

            ( name, args ) =
                case Parser.TextMacro.get (String.trim trimmed) of
                    Ok (Parser.TextMacro.MyMacro name_ args_) ->
                        ( name_, args_ )

                    Err error ->
                        ( "(no-name)", [] )
        in
        case Dict.get name substitutions of
            Just { prefix, arity } ->
                case arity of
                    Arity _ ->
                        leadingBlanks ++ prefix ++ " " ++ name ++ " " ++ String.join " " args

                    Grouped ->
                        leadingBlanks ++ prefix ++ " " ++ name ++ " " ++ "grouped(" ++ String.join " " args ++ ")"

            Nothing ->
                str


type Arity
    = Arity Int
    | Grouped


substitutions : Dict String { prefix : String, arity : Arity }
substitutions =
    Dict.fromList
        [ ( "item", { prefix = "|", arity = Arity 0 } )
        , ( "equation", { prefix = "||", arity = Arity 0 } )
        , ( "aligned", { prefix = "||", arity = Arity 0 } )
        , ( "mathmacros", { prefix = "||", arity = Arity 0 } )
        , ( "theorem", { prefix = "|", arity = Arity 0 } )
        , ( "indent", { prefix = "|", arity = Arity 0 } )
        , ( "numbered", { prefix = "|", arity = Arity 0 } )
        , ( "abstract", { prefix = "|", arity = Arity 0 } )
        , ( "bibitem", { prefix = "|", arity = Arity 1 } )
        , ( "desc", { prefix = "|", arity = Arity 1 } )
        , ( "setcounter", { prefix = "|", arity = Arity 1 } )
        , ( "contents", { prefix = "|", arity = Arity 0 } )
        ]


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
