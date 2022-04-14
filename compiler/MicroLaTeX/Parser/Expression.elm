module MicroLaTeX.Parser.Expression exposing
    ( State
    , eval
    , evalList
    , extractMessages
    , isReducible
    , parse
    , parseToState
    )

import List.Extra
import MicroLaTeX.Parser.Symbol as Symbol exposing (Symbol(..))
import MicroLaTeX.Parser.Token as Token exposing (Token(..), TokenType(..))
import Parser.Expr exposing (Expr(..))
import Parser.Helpers as Helpers exposing (Step(..), loop)
import Parser.Match as M
import Parser.Meta



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


parse : Int -> String -> ( List Expr, List String )
parse lineNumber str =
    let
        state =
            str |> Token.run |> initWithTokens lineNumber |> run

        exprs =
            state.committed

        messages =
            state.messages
    in
    ( exprs, messages )


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
    let
        _ =
            Debug.log "nextStep, STACK" state.stack
    in
    case List.Extra.getAt state.tokenIndex state.tokens of
        Nothing ->
            if List.isEmpty state.stack then
                Done state

            else
                -- the stack is not empty, so we need to handle the parse error
                recoverFromError state

        Just token ->
            pushToken token { state | tokenIndex = state.tokenIndex + 1 }
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

        MathToken _ ->
            pushOnStack token state

        CodeToken _ ->
            pushOnStack token state

        BS _ ->
            pushOnStack token state

        LB _ ->
            pushOnStack token state

        RB _ ->
            pushOnStack token state

        TokenError _ _ ->
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
            isReducible state.stack
    in
    if state.tokenIndex >= state.numberOfTokens || (reducible1 && not (isLBToken peek)) then
        let
            symbols =
                state.stack |> Symbol.convertTokens |> List.reverse
        in
        case List.head symbols of
            Just B ->
                let
                    _ =
                        Debug.log "!! PROBLEM STACK !!" (state.stack |> List.reverse |> Token.toString2)
                in
                case eval state.lineNumber (state.stack |> List.reverse) of
                    (Expr "ERROR" [ Text message _ ] _) :: rest ->
                        { state | stack = [], committed = rest ++ state.committed, messages = Helpers.prependMessage state.lineNumber message state.messages }

                    exprs ->
                        -- Function eval has reduced the stack, producing a list of expressiosn.  Push
                        -- them onto the list of committed expressions and clear the stack
                        { state | stack = [], committed = exprs ++ state.committed }

            Just M ->
                let
                    content =
                        state.stack |> List.reverse |> Token.toString

                    trailing =
                        String.right 1 content

                    committed =
                        if trailing == "$" && content == "$" then
                            let
                                ( first_, rest_ ) =
                                    case state.committed of
                                        first :: rest ->
                                            ( first, rest )

                                        _ ->
                                            ( Expr "red" [ Text "????(4)" (boostMeta state.lineNumber state.tokenIndex dummyLoc) ] dummyLocWithId, [] )
                            in
                            first_ :: Expr "red" [ Text "$" dummyLocWithId ] dummyLocWithId :: rest_

                        else if trailing == "$" then
                            Verbatim "math" (String.replace "$" "" content) (boostMeta state.tokenIndex 2 { begin = 0, end = 0, index = 0 }) :: state.committed

                        else
                            Expr "red" [ Text "$" dummyLocWithId ] dummyLocWithId
                                :: Verbatim "math" (String.replace "$" "" content) { begin = 0, end = 0, index = 0, id = makeId state.lineNumber state.tokenIndex }
                                :: state.committed
                in
                { state | stack = [], committed = committed }

            Just C ->
                let
                    content =
                        state.stack |> List.reverse |> Token.toString

                    trailing =
                        String.right 1 content

                    committed =
                        if trailing == "`" && content == "`" then
                            let
                                ( first_, rest_ ) =
                                    case state.committed of
                                        first :: rest ->
                                            ( first, rest )

                                        _ ->
                                            ( Expr "red" [ Text "????(4)" (boostMeta state.lineNumber state.tokenIndex dummyLoc) ] dummyLocWithId, [] )
                            in
                            first_ :: Expr "red" [ Text "`" (boostMeta state.lineNumber state.tokenIndex dummyLoc) ] dummyLocWithId :: rest_

                        else if trailing == "`" then
                            Verbatim "code" (String.replace "`" "" content) (boostMeta state.lineNumber state.tokenIndex { begin = 0, end = 0, index = 0 }) :: state.committed

                        else
                            Expr "red" [ Text "`" dummyLocWithId ] dummyLocWithId :: Verbatim "code" (String.replace "`" "" content) (boostMeta state.lineNumber state.tokenIndex { begin = 0, end = 0, index = 0 }) :: state.committed
                in
                { state | stack = [], committed = committed }

            _ ->
                state

    else
        state


eval : Int -> List Token -> List Expr
eval lineNumber tokens =
    let
        _ =
            Debug.log "!! TOK" tokens
    in
    case tokens of
        -- The reversed token list is of the form [LB name EXPRS RB], so return [Expr name (evalList EXPRS)]
        (S t m1) :: (BS m2) :: rest ->
            let
                _ =
                    Debug.log "!! CASE" 1
            in
            Text t m1 :: eval lineNumber (BS m2 :: rest)

        (S t m2) :: rest ->
            let
                _ =
                    Debug.log "!! CASE" 2
            in
            Text t m2 :: evalList Nothing lineNumber rest

        (BS m1) :: (S name m2) :: rest ->
            let
                _ =
                    Debug.log "!! CASE" 3

                ( a, b ) =
                    split rest
            in
            if b == [] then
                let
                    _ =
                        Debug.log "!! CASE" 4
                in
                [ Expr name (evalList (Just name) lineNumber rest) m1 ] |> Debug.log "!! CASE 4.1"

            else if List.head b |> isLBToken then
                let
                    _ =
                        Debug.log "!! CASE" 5
                in
                [ Expr name (evalList (Just name) lineNumber a ++ evalList (Just name) lineNumber b) m1 ]

            else
                let
                    _ =
                        Debug.log "!! CASE" 6
                in
                [ Expr name (evalList (Just name) lineNumber a) m1 ] ++ evalList (Just name) lineNumber b

        _ ->
            let
                _ =
                    Debug.log "!! CASE" 7
            in
            [ errorMessage1Part "{??}" ]


evalList : Maybe String -> Int -> List Token -> List Expr
evalList macroName lineNumber tokens =
    case List.head tokens of
        Just token ->
            case Token.type_ token of
                TLB ->
                    case M.match (Symbol.convertTokens2 tokens) of
                        -- there was no match for the left brace;
                        -- this is an error
                        Nothing ->
                            let
                                _ =
                                    Debug.log "!! CASE" 8
                            in
                            errorMessage3Part lineNumber ("\\" ++ (macroName |> Maybe.withDefault "x")) (Token.toString tokens) " ?}"

                        Just k ->
                            -- there are k matching tokens
                            let
                                _ =
                                    Debug.log "!! CASE" 9

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
                            let
                                _ =
                                    Debug.log "!! CASE" 10
                            in
                            expr :: evalList Nothing lineNumber (List.drop 1 tokens)

                        Nothing ->
                            let
                                _ =
                                    Debug.log "!! CASE" 11
                            in
                            [ errorMessage "•••?(7)" ]

        _ ->
            []


split : List Token -> ( List Token, List Token )
split tokens =
    case M.match (Symbol.convertTokens2 tokens) of
        Nothing ->
            -- errorMessage3Part lineNumber ("\\" ++ (macroName |> Maybe.withDefault "x")) (Token.toString tokens) " ?}"
            ( tokens, [] )

        Just k ->
            M.splitAt (k + 1) tokens


errorMessage1Part : String -> Expr
errorMessage1Part a =
    Expr "errorHighlight" [ Text a dummyLocWithId ] dummyLocWithId


errorMessage2Part : Int -> String -> String -> List Expr
errorMessage2Part lineNumber a b =
    [ Expr "errorHighlight" [ Text b dummyLocWithId ] dummyLocWithId, Expr "blue" [ Text a dummyLocWithId ] dummyLocWithId ]


errorMessage3Part : Int -> String -> String -> String -> List Expr
errorMessage3Part lineNumber a b c =
    [ Expr "blue" [ Text a dummyLocWithId ] dummyLocWithId, Expr "errorHighlight" [ Text b dummyLocWithId ] dummyLocWithId, Expr "errorHighlight" [ Text c dummyLocWithId ] dummyLocWithId ]


errorMessage : String -> Expr
errorMessage message =
    Expr "errorHighlight" [ Text message dummyLocWithId ] dummyLocWithId


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
            tokens |> List.reverse |> Symbol.convertTokens2 |> List.filter (\sym -> sym /= O)
    in
    if preliminary == [] then
        False

    else
        preliminary |> M.reducible


recoverFromError : State -> Step State State
recoverFromError state =
    let
        _ =
            Debug.log "STACK (recover)" state.stack
    in
    case List.reverse state.stack of
        (BS m1) :: (S fname m2) :: (LB m3) :: rest ->
            let
                _ =
                    Debug.log "STACK !!" ( List.length state.stack, state.stack |> List.reverse |> Token.toString2 )

                tail =
                    List.drop (m3.index + 1) state.tokens

                _ =
                    Debug.log "TOKENS !!" ( List.length tail, tail |> Token.toString2 )
            in
            Loop
                { state
                    | committed = errorMessage ("\\" ++ fname ++ "{") :: state.committed
                    , stack = []
                    , tokenIndex = m3.index + 1
                    , messages = Helpers.prependMessage state.lineNumber ("Missing right brace, column " ++ String.fromInt m3.begin) state.messages
                }

        -- braces with no intervening text
        (LB _) :: (RB meta) :: _ ->
            let
                _ =
                    Debug.log "!! CASE" 11
            in
            Loop
                { state
                    | committed = errorMessage "[?]" :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage state.lineNumber "Brackets need to enclose something" state.messages
                }

        -- consecutive left brackets
        (LB _) :: (LB meta) :: _ ->
            let
                _ =
                    Debug.log "!! CASE" 12
            in
            Loop
                { state
                    | committed = errorMessage "[" :: state.committed
                    , stack = []
                    , tokenIndex = meta.index
                    , messages = Helpers.prependMessage state.lineNumber "You have consecutive left brackets" state.messages
                }

        -- missing right bracket // OK
        (LB _) :: (S fName meta) :: rest ->
            let
                _ =
                    Debug.log "!! CASE" 13
            in
            Loop
                { state
                    | committed = errorMessage (errorSuffix rest) :: errorMessage2 ("[" ++ fName) :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage state.lineNumber "Missing right bracket" state.messages
                }

        -- space after left bracket // OK
        (LB _) :: (W " " meta) :: _ ->
            let
                _ =
                    Debug.log "!! CASE" 14
            in
            Loop
                { state
                    | committed = errorMessage "[ - can't have space after the bracket " :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage state.lineNumber "Can't have space after left bracket - try [something ..." state.messages
                }

        -- left bracket with nothing after it.  // OK
        (LB _) :: [] ->
            let
                _ =
                    Debug.log "!! CASE" 15
            in
            Done
                { state
                    | committed = errorMessage "[...?" :: state.committed
                    , stack = []
                    , tokenIndex = 0
                    , numberOfTokens = 0
                    , messages = Helpers.prependMessage state.lineNumber "That left bracket needs something after it" state.messages
                }

        -- extra right bracket
        (RB meta) :: _ ->
            let
                _ =
                    Debug.log "!! CASE" 16
            in
            Loop
                { state
                    | committed = errorMessage " extra ]?" :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage state.lineNumber "Extra right bracket(s)" state.messages
                }

        -- dollar sign with no closing dollar sign
        (MathToken meta) :: rest ->
            let
                _ =
                    Debug.log "!! CASE" 17

                content =
                    Token.toString rest

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
                _ =
                    Debug.log "!! CASE" 18

                content =
                    Token.toString rest

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
            let
                _ =
                    Debug.log "!! CASE" 19
            in
            recoverFromError1 state


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


makeId : Int -> Int -> String
makeId a b =
    String.fromInt a ++ "." ++ String.fromInt b


recoverFromError1 : State -> Step State State
recoverFromError1 state =
    let
        k =
            Symbol.balance <| Symbol.convertTokens (List.reverse state.stack)

        newStack =
            List.repeat k (RB (boostMeta state.lineNumber state.tokenIndex dummyLoc)) ++ state.stack

        newSymbols =
            Symbol.convertTokens (List.reverse newStack)

        reducible =
            M.reducible newSymbols
    in
    if reducible then
        let
            _ =
                Debug.log "!! CASE" 20
        in
        Done <|
            addErrorMessage " ]? " <|
                reduceState <|
                    { state
                        | stack = newStack
                        , tokenIndex = 0
                        , numberOfTokens = List.length newStack
                        , committed = errorMessage "[" :: state.committed
                        , messages = Helpers.prependMessage state.lineNumber ("Unmatched brackets: added " ++ String.fromInt k ++ " right brackets") state.messages
                    }

    else
        let
            _ =
                Debug.log "!! CASE" 21
        in
        Done
            { state
                | committed =
                    bracketError k
                        -- :: Expr "blue" [ Text (" " ++ Token.toString state.tokens) dummyLoc ] dummyLoc
                        :: state.committed
                , messages = Helpers.prependMessage state.lineNumber (bracketErrorAsString k) state.messages
            }


bracketError : Int -> Expr
bracketError k =
    if k < 0 then
        let
            brackets =
                List.repeat -k "]" |> String.join ""
        in
        errorMessage <| " " ++ brackets ++ " << Too many right brackets (" ++ String.fromInt -k ++ ")"

    else
        let
            brackets =
                List.repeat k "[" |> String.join ""
        in
        errorMessage <| " " ++ brackets ++ " << Too many left brackets (" ++ String.fromInt k ++ ")"


bracketErrorAsString : Int -> String
bracketErrorAsString k =
    if k < 0 then
        "Too many right brackets (" ++ String.fromInt -k ++ ")"

    else
        "Too many left brackets (" ++ String.fromInt k ++ ")"



-- HELPERS


dummyTokenIndex =
    0


dummyLoc =
    { begin = 0, end = 0, index = dummyTokenIndex }


dummyLocWithId =
    { begin = 0, end = 0, index = dummyTokenIndex, id = "dummy (3)" }



-- LOOP
