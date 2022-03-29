module MicroLaTeX.Parser.TransformLaTeX exposing (..)

--( toL0
--, toL0Aux
--)

import Dict exposing (Dict)
import Parser.MathMacro exposing (MathExpression(..))
import Parser.TextMacro exposing (MyMacro(..))



--fakeDebugLog1 =
--    \i label str -> Debug.log (String.fromInt i ++ ", " ++ label ++ " ") str
--


fakeDebugLog =
    \i label -> identity


xx1 =
    """
\\begin{theorem}
Ho ho ho
\\end{theorem}
"""


xx2 =
    """
\\begin{equation}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}
"""


xx2a =
    """
\\begin{theorem}
Ho ho ho! 
\\end{theorem}
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
    { i : Int, status : LXStatus, input : List String, output : List String, stack : List LXStatus }


type LXStatus
    = InVerbatimBlock String
    | InOrdinaryBlock String
    | LXNormal


toL0Aux : List String -> List String
toL0Aux list =
    loop { i = 0, input = list, output = [], status = LXNormal, stack = [] } nextState |> List.reverse


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
                    String.trimLeft line
            in
            case Parser.TextMacro.get trimmedLine of
                Err _ ->
                    if trimmedLine == "$$" then
                        Loop (nextState2 line (MyMacro "$$" []) { state | i = state.i + 1, input = List.drop 1 state.input }) |> fakeDebugLog state.i "(0a)"

                    else if List.isEmpty state.stack && line == "" then
                        Loop { state | i = state.i + 1, output = line :: state.output, status = LXNormal, input = List.drop 1 state.input } |> fakeDebugLog state.i "(0b)"

                    else
                        -- Just add the line to output
                        --- Loop { state | output = line :: state.output, input = List.drop 1 state.input } |> fakeDebugLog state.i  "(0b)"
                        state
                            |> handleError line
                            |> (\st -> { st | input = List.drop 1 state.input, i = state.i + 1 })
                            |> fakeDebugLog state.i "(0c)"
                            |> Loop

                Ok myMacro ->
                    case List.head state.stack of
                        Nothing ->
                            Loop (nextState2 line myMacro { state | input = List.drop 1 state.input, i = state.i + 1 }) |> fakeDebugLog state.i "(0d)"

                        Just foo ->
                            let
                                _ =
                                    Debug.log "FOO (0d)" foo
                            in
                            Loop (nextState2 line myMacro { state | input = List.drop 1 state.input, i = state.i + 1 }) |> fakeDebugLog state.i "(0e)"


handleError : String -> State -> State
handleError line state =
    case state.status of
        InVerbatimBlock name ->
            let
                endTag =
                    "\\end{" ++ name ++ "}"

                outputHead =
                    List.head state.output
            in
            case outputHead of
                Nothing ->
                    { state | output = line :: state.output }

                Just "" ->
                    { state | output = line :: "\\red{^^^ missing end tag (1)}" :: state.output, status = LXNormal }

                _ ->
                    if outputHead == Just endTag then
                        { state | output = line :: "" :: List.drop 1 state.output, status = LXNormal }

                    else
                        { state | output = line :: state.output }

        InOrdinaryBlock name ->
            let
                endTag =
                    "\\end{" ++ name ++ "}" |> Debug.log "END TAG"

                outputHead =
                    List.head state.output |> Debug.log "OUTPUT HEAD"

                _ =
                    Debug.log "LINE" line
            in
            if line == "" then
                { state | output = "" :: "\\red{^^^ missing end tag (2)}" :: state.output, status = LXNormal, stack = List.drop 1 state.stack } |> fakeDebugLog state.i "ERROR (1)"

            else
                case outputHead of
                    Nothing ->
                        { state | output = line :: state.output }

                    Just "" ->
                        if List.isEmpty state.stack then
                            { state | output = "" :: "\\red{^^^ missing end tag (3)}" :: state.output, status = LXNormal } |> fakeDebugLog state.i "ERROR (2)"

                        else
                            { state | output = line :: state.output }

                    _ ->
                        if outputHead == Just endTag && List.isEmpty state.stack then
                            { state | output = line :: "" :: List.drop 1 state.output, status = LXNormal }

                        else
                            { state | output = line :: state.output }

        LXNormal ->
            { state | output = line :: state.output }


nextState2 line (MyMacro name args) state =
    let
        firstArg =
            List.head args |> Maybe.withDefault "((no-first-arg))"
    in
    if name == "begin" && List.member firstArg [ "code", "equation" ] then
        -- HANDLE CODE BLOCKS, BEGIN
        { state | output = ("|| " ++ firstArg) :: state.output, status = InVerbatimBlock firstArg, stack = InVerbatimBlock firstArg :: state.stack } |> fakeDebugLog state.i "(1)"

    else if name == "end" && args == [ "code" ] then
        -- HANDLE CODE BLOCKS, END
        { state | output = "" :: state.output, status = LXNormal, stack = List.drop 1 state.stack } |> fakeDebugLog state.i "(2)"

    else if name == "$$" && state.status == LXNormal then
        -- HANDLE $$ BLOCK, BEGIN
        { state | output = "$$" :: state.output, status = InVerbatimBlock "$$", stack = InVerbatimBlock "$$" :: state.stack } |> fakeDebugLog state.i "(3)"

    else if List.member name [ "$$" ] && state.status == InVerbatimBlock name then
        -- HANDLE $$ BLOCK, END
        { state | output = "" :: state.output, status = LXNormal, stack = List.drop 1 state.stack } |> fakeDebugLog state.i "(4)"

    else if state.status == InVerbatimBlock "```" then
        -- HANDLE ``` BLOCK, INTERIOR
        { state | output = line :: state.output } |> fakeDebugLog state.i "(3.1)"

    else if name == "begin" && state.status == LXNormal then
        -- HANDLE ENVIRONMENT, BEGIN
        { state | output = transformHeader name args line :: state.output, status = InOrdinaryBlock firstArg, stack = InOrdinaryBlock firstArg :: state.stack } |> fakeDebugLog state.i "(5)"

    else if name == "end" && state.status == InOrdinaryBlock firstArg then
        -- HANDLE ENVIRONMENT, END
        { state | output = "" :: state.output, stack = List.drop 1 state.stack } |> fakeDebugLog state.i "(6)"

    else if state.status == LXNormal && List.member name [ "item", "numbered", "bibref", "desc", "contents" ] then
        -- HANDLE \item, \bibref, etc
        { state | output = (String.replace ("\\" ++ name) ("| " ++ name) line |> fixArgs) :: state.output } |> fakeDebugLog state.i "(7)"
        -- ??

    else if state.status == InOrdinaryBlock name then
        if String.trimLeft line == "" then
            { state | output = "" :: state.output } |> fakeDebugLog state.i "(8)"

        else
            { state | output = transformHeader name args line :: state.output } |> fakeDebugLog state.i "(9)"

    else
        { state | output = line :: state.output } |> fakeDebugLog state.i "(10)"


transformHeader : String -> List String -> String -> String
transformHeader name args str =
    if name == "begin" then
        transformBegin args str

    else
        transformOther name args str


transformOther name args str =
    let
        target =
            if name == "$$" then
                "$$"

            else
                "\\" ++ name
    in
    case Dict.get name substitutions of
        Nothing ->
            str

        Just { prefix } ->
            String.replace target ("| " ++ name) str |> fixArgs


fixArgs str =
    str |> String.replace "{" " " |> String.replace "}" " "


transformBegin args str =
    case List.head args of
        Nothing ->
            str

        Just environmentName ->
            let
                target =
                    "\\begin{" ++ environmentName ++ "}"
            in
            case Dict.get environmentName substitutions of
                Nothing ->
                    str

                Just { prefix } ->
                    String.replace target (prefix ++ " " ++ environmentName) str


transformBlockHeader2 : String -> String -> String
transformBlockHeader2 blockName str =
    transformBlockHeader_ blockName str |> String.replace "[" " " |> String.replace "]" " "


transformBlockHeader_ : String -> String -> String
transformBlockHeader_ blockName str =
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
