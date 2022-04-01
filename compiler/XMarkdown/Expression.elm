module XMarkdown.Expression exposing
    ( State
    , eval
    , evalList
    , extractMessages
    , isReducible
    , parse
    , parseToState
    )

import L0.Parser.Expression
import List.Extra
import Parser.Expr exposing (Expr(..))
import Parser.Helpers as Helpers exposing (Step(..), loop)
import Tools
import XMarkdown.Match as M
import XMarkdown.Symbol as Symbol exposing (Symbol(..))
import XMarkdown.Token as Token exposing (Token(..), TokenType(..))


forkLogWidth =
    12



-- TYPES


type alias State =
    { step : Int
    , tokens : List Token
    , numberOfTokens : Int
    , tokenIndex : Int
    , committed : List Expr
    , stack : List Token
    , messages : List String
    , lineNumber : Int
    }


extractMessages : State -> List String
extractMessages state =
    state.messages



-- STATE FOR THE PARSER


initWithTokens : Int -> List Token -> State
initWithTokens lineNumber tokens =
    { step = 0
    , tokens = List.reverse tokens
    , numberOfTokens = List.length tokens
    , tokenIndex = 0
    , committed = []
    , stack = []
    , messages = []
    , lineNumber = lineNumber
    }



-- Exposed functions


parse : Int -> String -> List Expr
parse lineNumber str =
    str
        |> Token.run
        |> Tools.forklogCyan "TOKENS" forkLogWidth Token.toString2
        |> initWithTokens lineNumber
        |> run
        |> .committed
        |> Tools.forklogCyan "LENGTH" forkLogWidth List.length


parseToState : Int -> String -> State
parseToState lineNumber str =
    str
        |> Token.run
        |> initWithTokens lineNumber
        |> run



-- PARSER


run : State -> State
run state =
    loop state nextStep
        |> (\state_ -> { state_ | committed = List.reverse state_.committed })


nextStep : State -> Step State State
nextStep state =
    case List.Extra.getAt state.tokenIndex state.tokens of
        Nothing ->
            if List.isEmpty state.stack then
                Done state

            else
                -- the stack is not empty, so we need to handle the parse error
                recoverFromError (state |> Tools.forklogBlue "RECOVER" 12 (.stack >> List.reverse >> Token.toString2))

        Just token ->
            pushToken token { state | tokenIndex = state.tokenIndex + 1 }
                |> Tools.forklogBlue "STACK" forkLogWidth (.stack >> Token.toString2)
                |> reduceState
                |> (\st -> { st | step = st.step + 1 })
                |> Loop



-- PUSH


pushToken : Token -> State -> State
pushToken token state =
    case token of
        S _ _ ->
            pushOrCommit token state

        W _ _ ->
            pushOrCommit token state

        _ ->
            pushOnStack token state


pushOnStack : Token -> State -> State
pushOnStack token state =
    { state | stack = token :: state.stack }


pushOrCommit : Token -> State -> State
pushOrCommit token state =
    if List.isEmpty state.stack then
        commit token state

    else
        push token state


commit : Token -> State -> State
commit token state =
    case exprOfToken token of
        Nothing ->
            state

        Just expr ->
            { state | committed = expr :: state.committed }


exprOfToken : Token -> Maybe Expr
exprOfToken token =
    case token of
        S str loc ->
            Just (Text str loc)

        W str loc ->
            Just (Text str loc)

        _ ->
            Nothing


push : Token -> State -> State
push token state =
    { state | stack = token :: state.stack }



-- REDUCE


isLBToken maybeTok =
    case maybeTok of
        Just (LB _) ->
            True

        _ ->
            False


reduceState : State -> State
reduceState state =
    let
        peek : Maybe Token
        peek =
            List.Extra.getAt state.tokenIndex state.tokens

        reducible1 =
            isReducible state.stack |> Tools.forklogRed "SYMBOLS (!!)" forkLogWidth identity
    in
    -- if state.tokenIndex >= state.numberOfTokens || (reducible1 && not (isLBToken peek)) then
    if state.tokenIndex >= state.numberOfTokens || reducible1 then
        let
            symbols =
                state.stack |> Symbol.convertTokens |> List.reverse |> Tools.forklogRed "SYMBOLS" forkLogWidth identity
        in
        case List.head symbols of
            Just SAT ->
                handleAt symbols state

            Just M ->
                handleMathSymbol symbols state

            Just C ->
                handleCodeSymbol symbols state

            Just SBold ->
                handleBoldSymbol symbols state

            Just SItalic ->
                handleItalicSymbol symbols state

            Just LBracket ->
                if symbols == [ LBracket, RBracket, LParen, RParen ] then
                    handleLink symbols state
                    --else if symbols == [ LBracket, RBracket ] then

                else
                    handleBracketedText state |> Tools.forklogRed "HANDLE[]" forkLogWidth identity

            --else
            --    state
            Just SImage ->
                handleImage symbols state

            Just LParen ->
                handleParens symbols state

            _ ->
                state

    else
        state


takeMiddle : List a -> List a
takeMiddle list =
    list
        |> List.drop 1
        |> List.reverse
        |> List.drop 1


handleLink : List Symbol -> State -> State
handleLink symbols state =
    let
        _ =
            Tools.forklogRed "SYMBOLS (2)" forkLogWidth identity symbols

        expr =
            case state.stack of
                [ RP _, S url _, LP _, RB _, S linkText _, LB _ ] ->
                    Expr "link" [ Text (linkText ++ " " ++ url) meta ] meta

                [ RP _, LP _, RB _, S linkText _, LB _ ] ->
                    Expr "red" [ Text ("[" ++ linkText ++ "](no label)") meta ] meta

                [ RP _, S url _, LP _, RB _, LB _ ] ->
                    Expr "red" [ Text ("[Link: no label](" ++ url ++ ")") meta ] meta

                _ ->
                    Expr "red" [ Text "[Link: no label or url]" meta ] meta

        _ =
            Tools.forklogRed "OUT" forkLogWidth identity expr

        meta =
            { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }
    in
    { state | committed = expr :: state.committed, stack = [] }


handleBracketedText : State -> State
handleBracketedText state =
    let
        str =
            case state.stack of
                [ RP _, S str_ _, LP _ ] ->
                    "[" ++ str_ ++ "]"

                _ ->
                    state.stack |> List.reverse |> Token.toString

        meta =
            { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }

        expr =
            Text str meta
    in
    { state | committed = expr :: state.committed, stack = [] }



--
--let
--    _ =
--        Tools.forklogRed "HNDL, STACK" forkLogWidth .stack state
--
--    expr =
--        case state.stack of
--            [ RB _, S txt meta, LB _ ] ->
--                Text ("[" ++ txt ++ "]") meta
--
--            _ ->
--                ( "??", dummyMeta )
--
--    expr =
--        Text ("[" ++ txt ++ "]") meta
--in
--{ state | committed = expr :: state.committed, stack = [] }


handleImage : List Symbol -> State -> State
handleImage symbols state =
    let
        data =
            case state.stack of
                [ RP _, S url _, LP _, RB _, S label _, LB _, Image _ ] ->
                    { label = label, url = url }

                _ ->
                    { label = "no image label", url = "no image url" }

        expr =
            Expr "image" [ Text (data.url ++ " " ++ data.label) meta ] meta |> Tools.forklogRed "EXPR" forkLogWidth identity

        meta =
            { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }
    in
    { state | committed = expr :: state.committed, stack = [] }


handleAt : List Symbol -> State -> State
handleAt symbols state =
    let
        content =
            state.stack
                |> List.reverse
                |> Token.toString
                |> String.dropLeft 1
                |> Tools.forklogRed "STACK (AT)" forkLogWidth identity

        expr : List Expr
        expr =
            L0.Parser.Expression.parse 0 content
    in
    { state | committed = expr ++ state.committed, stack = [] }


handleParens : List Symbol -> State -> State
handleParens symbols state =
    let
        str =
            case state.stack of
                [ RP _, S str_ _, LP _ ] ->
                    "(" ++ str_ ++ ")"

                _ ->
                    state.stack |> List.reverse |> Token.toString

        meta =
            { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }

        expr =
            Text str meta
    in
    { state | committed = expr :: state.committed, stack = [] }


handleItalicSymbol : List Symbol -> State -> State
handleItalicSymbol symbols state =
    if symbols == [ SItalic, SItalic ] then
        let
            content =
                takeMiddle state.stack |> Token.toString2

            meta =
                { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }

            expr =
                Expr "italic" [ Text content meta ] meta
        in
        { state | stack = [], committed = expr :: state.committed }

    else
        state


handleBoldSymbol : List Symbol -> State -> State
handleBoldSymbol symbols state =
    if symbols == [ SBold, SBold ] then
        let
            content =
                takeMiddle state.stack |> Token.toString2

            meta =
                { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }

            expr =
                Expr "bold" [ Text content meta ] meta
        in
        { state | stack = [], committed = expr :: state.committed }

    else
        state


handleMathSymbol : List Symbol -> State -> State
handleMathSymbol symbols state =
    if symbols == [ M, M ] then
        let
            content =
                takeMiddle state.stack |> Token.toString2

            expr =
                Verbatim "math" content { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }
        in
        { state | stack = [], committed = expr :: state.committed }

    else
        state


handleCodeSymbol : List Symbol -> State -> State
handleCodeSymbol symbols state =
    if symbols == [ C, C ] then
        let
            content =
                takeMiddle state.stack |> Token.toString2

            expr =
                Verbatim "code" content { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }
        in
        { state | stack = [], committed = expr :: state.committed }

    else
        state


handleSymbol1 : String -> String -> State -> State
handleSymbol1 name symbol state =
    let
        _ =
            Tools.forklogRed "SYM" forkLogWidth identity symbol

        content =
            state.stack |> List.reverse |> Tools.forklogYellow "CONT" forkLogWidth identity |> Token.toString2

        trailing =
            String.right 1 content |> Tools.forklogYellow "TRAILING" forkLogWidth identity

        committed =
            --if trailing == symbol && content == symbol then
            --    let
            --        ( first_, rest_ ) =
            --            case state.committed of
            --                first :: rest ->
            --                    ( first, rest )
            --
            --                _ ->
            --                    ( Expr "red" [ Text "????(4)" (boostMeta state.lineNumber state.tokenIndex dummyLoc) ] dummyLocWithId, [] )
            --    in
            --    first_ :: Expr "red" [ Text "$" dummyLocWithId ] dummyLocWithId :: rest_
            if trailing == symbol then
                Verbatim "math" (String.replace symbol "" content) (boostMeta state.tokenIndex 2 { begin = 0, end = 0, index = 0 })
                    :: state.committed
                    |> Tools.forklogRed "(1)" forkLogWidth identity

            else
                (Expr "red" [ Text symbol dummyLocWithId ] dummyLocWithId
                    :: Verbatim name (String.replace symbol "" content) { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }
                    :: state.committed
                )
                    |> Tools.forklogRed "(2)" forkLogWidth identity
    in
    { state | stack = [], committed = committed }


eval : Int -> List Token -> List Expr
eval lineNumber tokens =
    case tokens of
        (S t m2) :: rest ->
            Text t m2 :: evalList Nothing lineNumber rest

        _ ->
            errorMessage2Part lineNumber "\\" "{??}(5)"


evalList : Maybe String -> Int -> List Token -> List Expr
evalList macroName lineNumber tokens =
    case List.head tokens of
        Just token ->
            case Token.type_ token of
                TLB ->
                    case M.match (Symbol.convertTokens tokens) of
                        Nothing ->
                            errorMessage3Part lineNumber ("\\" ++ (macroName |> Maybe.withDefault "x")) (Token.toString2 tokens) " ?}"

                        Just k ->
                            let
                                ( a, b ) =
                                    M.splitAt (k + 1) tokens

                                aa =
                                    -- drop the leading and trailing LB, RG
                                    a |> List.take (List.length a - 1) |> List.drop 1
                            in
                            eval lineNumber aa ++ evalList Nothing lineNumber b

                _ ->
                    case exprOfToken token of
                        Just expr ->
                            expr :: evalList Nothing lineNumber (List.drop 1 tokens)

                        Nothing ->
                            [ errorMessage "•••?(7)" ]

        _ ->
            []


errorMessage2Part : Int -> String -> String -> List Expr
errorMessage2Part lineNumber a b =
    [ Expr "red" [ Text b dummyLocWithId ] dummyLocWithId, Expr "blue" [ Text a dummyLocWithId ] dummyLocWithId ]


errorMessage3Part : Int -> String -> String -> String -> List Expr
errorMessage3Part lineNumber a b c =
    [ Expr "blue" [ Text a dummyLocWithId ] dummyLocWithId, Expr "blue" [ Text b dummyLocWithId ] dummyLocWithId, Expr "red" [ Text c dummyLocWithId ] dummyLocWithId ]


errorMessage : String -> Expr
errorMessage message =
    Expr "red" [ Text message dummyLocWithId ] dummyLocWithId


errorMessageLarge : String -> Expr
errorMessageLarge message =
    Expr "large" [ Expr "bold" [ Expr "red" [ Text message dummyLocWithId ] dummyLocWithId ] dummyLocWithId ] dummyLocWithId


errorMessageBold : String -> Expr
errorMessageBold message =
    Expr "bold" [ Expr "red" [ Text message dummyLocWithId ] dummyLocWithId ] dummyLocWithId


errorMessage2 : String -> Expr
errorMessage2 message =
    Expr "blue" [ Text message dummyLocWithId ] dummyLocWithId


addErrorMessage : String -> State -> State
addErrorMessage message state =
    let
        committed =
            errorMessage message :: state.committed
    in
    { state | committed = committed }


isReducible : List Token -> Bool
isReducible tokens =
    let
        preliminary =
            tokens |> List.reverse |> Symbol.convertTokens |> List.filter (\sym -> sym /= O) |> Tools.forklogYellow "SYMBOLS" forkLogWidth identity
    in
    if preliminary == [] then
        False

    else
        preliminary |> M.reducible |> Tools.forklogYellow "REDUCIBLE ?" forkLogWidth identity



-- TODO: finish recoverFromError


recoverFromError : State -> Step State State
recoverFromError state =
    let
        _ =
            Tools.forklogRed "RECOVER" forkLogWidth .stack state
    in
    case List.reverse state.stack of
        (LB _) :: (S txt meta) :: (RB _) :: [] ->
            Loop { state | stack = [], committed = Text ("[" ++ txt ++ "]") meta :: [] }

        (Italic meta) :: [] ->
            if List.isEmpty state.committed then
                Loop { state | stack = [], committed = errorMessage "_" :: [] }

            else
                let
                    expr =
                        case List.head state.committed of
                            Just (Text str1 meta1) ->
                                Expr "italic" [ Text str1 meta1 ] meta1

                            _ ->
                                Expr "italic" [ Text "??" meta ] meta
                in
                Loop
                    { state
                        | stack = []
                        , committed = expr :: errorMessage "_" :: List.drop 1 state.committed
                        , tokenIndex = meta.index + 1
                        , messages = [ "!!" ]
                    }

        (Bold meta) :: [] ->
            if List.isEmpty state.committed then
                Loop { state | stack = [], committed = errorMessage "*" :: [] }

            else
                let
                    expr =
                        case List.head state.committed of
                            Just (Text str1 meta1) ->
                                Expr "bold" [ Text str1 meta1 ] meta1

                            _ ->
                                Expr "bold" [ Text "??" meta ] meta
                in
                Loop
                    { state
                        | stack = []
                        , committed = expr :: errorMessage "*" :: List.drop 1 state.committed
                        , tokenIndex = meta.index + 1
                        , messages = [ "!!" ]
                    }

        (Italic _) :: (S str meta) :: [] ->
            Loop
                { state
                    | stack = []
                    , committed = errorMessage "_" :: Expr "italic" [ Text str meta ] meta :: state.committed
                    , tokenIndex = meta.index + 1
                    , messages = [ "!!" ]
                }

        (Bold _) :: (S str meta) :: [] ->
            Loop
                { state
                    | stack = []
                    , committed = errorMessage "*" :: Expr "bold" [ Text str meta ] meta :: state.committed
                    , tokenIndex = meta.index + 1
                    , messages = [ "!!" ]
                }

        -- dollar sign with no closing dollar sign
        (MathToken meta) :: rest ->
            let
                content =
                    Token.toString2 rest

                message =
                    if content == "" then
                        "$?$"

                    else
                        "$ "
            in
            Loop
                { state
                    | committed = errorMessage message :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , numberOfTokens = 0
                    , messages = Helpers.prependMessage state.lineNumber "opening dollar sign needs to be matched with a closing one" state.messages
                }

        -- backtick with no closing backtick
        (CodeToken meta) :: rest ->
            let
                content =
                    Token.toString2 rest

                message =
                    if content == "" then
                        "`?`"

                    else
                        "` "
            in
            Loop
                { state
                    | committed = errorMessageBold message :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , numberOfTokens = 0
                    , messages = Helpers.prependMessage state.lineNumber "opening backtick needs to be matched with a closing one" state.messages
                }

        _ ->
            Done state


errorSuffix rest =
    case rest of
        [] ->
            "]?"

        (W _ _) :: [] ->
            "]?"

        _ ->
            ""


boostMeta : Int -> Int -> { begin : Int, end : Int, index : Int } -> { begin : Int, end : Int, index : Int, id : String }
boostMeta lineNumber tokenIndex { begin, end, index } =
    { begin = begin, end = end, index = index, id = makeId lineNumber tokenIndex }


dummyMeta =
    { begin = 0, end = 0, index = 0, id = "??" }


makeId : Int -> Int -> String
makeId a b =
    String.fromInt a ++ "." ++ String.fromInt b



-- HELPERS


dummyTokenIndex =
    0


dummyLoc =
    { begin = 0, end = 0, index = dummyTokenIndex }


dummyLocWithId =
    { begin = 0, end = 0, index = dummyTokenIndex, id = "dummy (3)" }



-- LOOP
