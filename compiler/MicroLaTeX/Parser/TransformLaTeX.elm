module MicroLaTeX.Parser.TransformLaTeX exposing
    ( LXStatus(..)
    , State
    , Step(..)
    , endBlockOfLXStatus
    , fakeDebugLog
    , fixArgs
    , handleError
    , leadingBlanks
    , loop
    , nextState
    , nextState2
    , substitutions
    , toL0
    , transformBegin
    , transformHeader
    , transformOther
    , verbatimBlockNames
    , xx1
    , xx2
    , xx3
    , xx4
    )

import Dict exposing (Dict)
import List.Extra
import Parser.Settings exposing (Arity, blockData)
import Parser.TextMacro exposing (MyMacro(..))



--fakeDebugLog =
--    \i label str -> Debug.log (String.fromInt i ++ ", " ++ label ++ " ") str
--


fakeDebugLog =
    \_ _ -> identity


xx1 =
    """
\\begin{code}
\\begin{mathmacros}
\\newcommand{\\bra}[0]{\\]langle}
\\end{mathmacros}
\\end{code}
"""


xx2 =
    "\n\\begin{theorem}\nHo ho ho\n"


xx3 =
    "\n\\begin{theorem}\nHo ho ho\n\\end{th}"


xx4 =
    """
\\bibitem{AA}
Foo bar
"""



-- TRANSFORMS


{-| Map a list of strings to from microLaTeX block format to L0 block format.
It seems that function 'indentStrings' is unnecessary.
TODO: test the foregoing.
TODO: at the moment, there is no error-handling. Think about this
-}



--toL0 : List String -> List String
--toL0 strings =
--    strings |> toL0Aux


verbatimBlockNames =
    [ "math", "equation", "aligned", "code", "mathmacros", "verbatim", "$$" ]


type alias State =
    { i : Int, status : LXStatus, input : List String, output : List String, stack : List LXStatus }


type LXStatus
    = InVerbatimBlock String
    | InOrdinaryBlock String
    | LXNormal


endBlockOfLXStatus : LXStatus -> Maybe String
endBlockOfLXStatus status =
    case status of
        InVerbatimBlock name ->
            Just ("\\end{" ++ name ++ "}")

        InOrdinaryBlock name ->
            Just ("\\end{" ++ name ++ "}")

        LXNormal ->
            Nothing


toL0 : List String -> List String
toL0 list =
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
                        -- Add the line to output with possible error handling
                        state
                            |> handleError line
                            |> (\st -> { st | input = List.drop 1 state.input, i = state.i + 1 })
                            |> fakeDebugLog state.i "(0c)"
                            |> Loop

                Ok myMacro ->
                    case List.head state.stack of
                        Nothing ->
                            Loop (nextState2 line myMacro { state | input = List.drop 1 state.input, i = state.i + 1 }) |> fakeDebugLog state.i "(0d)"

                        Just _ ->
                            Loop (nextState2 line myMacro { state | input = List.drop 1 state.input, i = state.i + 1 }) |> fakeDebugLog state.i "(0e)"


nextState2 line (MyMacro name args) state =
    let
        firstArg =
            List.head args |> Maybe.withDefault "((no-first-arg))"
    in
    if state.status == InVerbatimBlock "code" then
        -- HANDLE ``` BLOCK, INTERIOR
        { state | output = line :: state.output } |> fakeDebugLog state.i "(3.1)"

    else if name == "begin" && List.member firstArg [ "code", "equation", "aligned" ] then
        -- HANDLE VERBATIM BLOCKS (CODE, EQUATION, ALIGNED), BEGIN
        { state | output = ("|| " ++ firstArg) :: state.output, status = InVerbatimBlock firstArg, stack = InVerbatimBlock firstArg :: state.stack } |> fakeDebugLog state.i "(1)"

    else if name == "end" && List.member firstArg [ "code", "equation", "aligned" ] then
        -- HANDLE CODE BLOCKS, END
        { state | output = "" :: state.output, status = LXNormal, stack = List.drop 1 state.stack } |> fakeDebugLog state.i "(2)"

    else if name == "$$" && state.status == LXNormal then
        -- HANDLE $$ BLOCK, BEGIN
        { state | output = line :: state.output, status = InVerbatimBlock "$$", stack = InVerbatimBlock "$$" :: state.stack } |> fakeDebugLog state.i "(3)"

    else if List.member name [ "$$" ] && state.status == InVerbatimBlock name then
        -- HANDLE $$ BLOCK, END
        { state | output = "" :: state.output, status = LXNormal, stack = List.drop 1 state.stack } |> fakeDebugLog state.i "(4)"

    else if name == "```" && state.status == LXNormal then
        -- HANDLE ``` BLOCK, BEGIN
        { state | output = line :: state.output, status = InVerbatimBlock "```", stack = InVerbatimBlock "```" :: state.stack } |> fakeDebugLog state.i "(3)"

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

    else if Just line == (List.head state.stack |> Maybe.andThen endBlockOfLXStatus) then
        { state | output = "" :: state.output, stack = List.drop 1 state.stack } |> fakeDebugLog state.i "(10)"

    else
        let
            newStack =
                List.drop 1 state.stack
        in
        if name == "end" && not (List.member (List.Extra.last state.stack) [ Just (InVerbatimBlock "code"), Just (InVerbatimBlock "equation"), Just (InVerbatimBlock "aligned") ]) then
            { state | output = "\\red{^^^ missmatched end tags}" :: "" :: state.output, stack = newStack } |> fakeDebugLog state.i "(12)"

        else
            { state | output = line :: state.output } |> fakeDebugLog state.i "(12)"


handleError : String -> State -> State
handleError line state =
    case state.status of
        InVerbatimBlock name ->
            let
                --_ =
                --    Debug.log "handleError, InVerbatimBlock, LINE" line
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
                --_ =
                --    Debug.log "LINE" line
                endTag =
                    "\\end{" ++ name ++ "}"

                -- |> Debug.log "endTag"
                outputHead =
                    List.head state.output

                --  |> Debug.log "outputHead"
                n =
                    Maybe.map leadingBlanks outputHead |> Maybe.withDefault 0
            in
            if line == "" then
                if n > 0 then
                    { state | output = "" :: state.output, status = LXNormal } |> fakeDebugLog state.i "ERROR (1)"

                else
                    { state | output = "" :: "\\red{^^^ missing end tag (2)}" :: state.output, status = LXNormal, stack = List.drop 1 state.stack } |> fakeDebugLog state.i "ERROR (2a)"

            else
                case outputHead of
                    Nothing ->
                        { state | output = line :: state.output }

                    Just "" ->
                        if List.isEmpty state.stack then
                            { state | output = "" :: "\\red{^^^ missing end tag (3)}" :: state.output, status = LXNormal } |> fakeDebugLog state.i "ERROR (3)"

                        else
                            { state | output = line :: state.output }

                    _ ->
                        if outputHead == Just endTag && List.isEmpty state.stack then
                            { state | output = line :: "" :: List.drop 1 state.output, status = LXNormal }

                        else
                            { state | output = line :: state.output }

        LXNormal ->
            { state | output = line :: state.output }



-- HELPERS


leadingBlanks : String -> Int
leadingBlanks str =
    let
        trimmed =
            String.trimLeft str
    in
    String.length str - String.length trimmed


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

        Just _ ->
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


substitutions : Dict String { prefix : String, arity : Arity }
substitutions =
    Dict.fromList Parser.Settings.blockData



--[ ( "item", { prefix = "|", arity = Arity 0 } )
--, ( "equation", { prefix = "||", arity = Arity 0 } )
--, ( "aligned", { prefix = "||", arity = Arity 0 } )
--, ( "mathmacros", { prefix = "||", arity = Arity 0 } )
--, ( "axiom", { prefix = "|", arity = Arity 0 } )
--, ( "theorem", { prefix = "|", arity = Arity 0 } )
--, ( "proposition", { prefix = "|", arity = Arity 0 } )
--, ( "corollary", { prefix = "|", arity = Arity 0 } )
--, ( "definition", { prefix = "|", arity = Arity 0 } )
--, ( "note", { prefix = "|", arity = Arity 0 } )
--, ( "lemma", { prefix = "|", arity = Arity 0 } )
--, ( "example", { prefix = "|", arity = Arity 0 } )
--, ( "problem", { prefix = "|", arity = Arity 0 } )
--, ( "remark", { prefix = "|", arity = Arity 0 } )
--, ( "indent", { prefix = "|", arity = Arity 0 } )
--, ( "numbered", { prefix = "|", arity = Arity 0 } )
--, ( "abstract", { prefix = "|", arity = Arity 0 } )
--, ( "bibitem", { prefix = "|", arity = Arity 1 } )
--, ( "desc", { prefix = "|", arity = Arity 1 } )
--, ( "setcounter", { prefix = "|", arity = Arity 1 } )
--, ( "contents", { prefix = "|", arity = Arity 0 } )
--]
