module MicroLaTeX.Parser.TransformLaTeX exposing
    ( toL0
    , toL0Aux
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


xx6 =
    "\\begin{theorem}\n  AAA\n  \n  $$\n  x^2\n  $$\n  \n  BBB\n\\end{theorem}"



-- TRANSFORMS


{-| Map a list of strings to from microLaTeX block format to L0 block format.
It seems that function 'indentStrings' is unnecessary.
TODO: test the foregoing.
TODO: at the moment, there is no error-handling. Think about this
-}
toL0 : List String -> List String
toL0 strings =
    strings |> toL0Aux


verbatimBlockNames =
    [ "math", "equation", "aligned", "code", "mathmacros", "verbatim", "$$" ]


type alias State =
    { status : LXStatus, input : List String, output : List String }


type LXStatus
    = InVerbatimBlock String
    | InOrdinaryBlock
    | LXNormal


toL0Aux : List String -> List String
toL0Aux list =
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
