module MicroLaTeX.Parser.Expression exposing
    ( State
    , eval
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
        |> initWithTokens lineNumber
        |> run
        |> .committed


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


reduceState : State -> State
reduceState state =
    let
        peek =
            List.Extra.getAt state.tokenIndex state.tokens

        isStringToken maybeTok =
            case maybeTok of
                Just (S _ _) ->
                    True

                _ ->
                    False

        reducible_ =
            isReducible state.stack
                && isStringToken peek
    in
    if state.tokenIndex >= state.numberOfTokens || reducible_ then
        let
            symbols =
                state.stack |> Symbol.convertTokens |> List.reverse
        in
        case List.head symbols of
            Just B ->
                case eval state.lineNumber (state.stack |> List.reverse) of
                    (Expr "??(3)" [ Text message _ ] _) :: rest ->
                        { state | stack = [], committed = rest ++ state.committed, messages = Helpers.prependMessage state.lineNumber message state.messages }

                    whatever ->
                        { state | stack = [], committed = whatever ++ state.committed }

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
                                            ( Expr "red" [ Text "????(4)" dummyLoc ] dummyLoc, [] )
                            in
                            first_ :: Expr "red" [ Text "$" dummyLoc ] dummyLoc :: rest_

                        else if trailing == "$" then
                            Verbatim "math" (String.replace "$" "" content) { begin = 0, end = 0, index = 0 } :: state.committed

                        else
                            Expr "red" [ Text "$" dummyLoc ] dummyLoc :: Verbatim "math" (String.replace "$" "" content) { begin = 0, end = 0, index = 0 } :: state.committed
                in
                { state | stack = [], committed = committed }

            Just C ->
                { state | stack = [], committed = Verbatim "code" (String.replace "`" "" <| Token.toString <| unbracket <| List.reverse state.stack) { begin = 0, end = 0, index = 0 } :: state.committed }

            _ ->
                state

    else
        state


{-| remove first and last token
-}
unbracket : List a -> List a
unbracket list =
    List.drop 1 (List.take (List.length list - 1) list)


eval : Int -> List Token -> List Expr
eval lineNumber tokens =
    case tokens of
        -- The reversed token list is of the form [LB name EXPRS RB], so return [Expr name (evalList EXPRS)]
        (S t m2) :: rest ->
            Text t m2 :: evalList Nothing lineNumber rest

        (BS m1) :: (S name _) :: rest ->
            [ Expr name (evalList (Just name) lineNumber rest) m1 ]

        _ ->
            -- [ errorMessageInvisible lineNumber "missing macro name", errorMessage <| "??" ]
            errorMessage2Part lineNumber "\\" "{??}(5)"


evalList : Maybe String -> Int -> List Token -> List Expr
evalList macroName lineNumber tokens =
    case List.head tokens of
        Just token ->
            case Token.type_ token of
                TLB ->
                    case M.match (Symbol.convertTokens2 tokens) of
                        Nothing ->
                            errorMessage3Part lineNumber ("\\" ++ (macroName |> Maybe.withDefault "x")) (Token.toString tokens) " ?}"

                        Just k ->
                            let
                                ( a, b ) =
                                    M.splitAt (k + 1) tokens

                                aa =
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
    [ Expr "red" [ Text b dummyLoc ] dummyLoc, Expr "blue" [ Text a dummyLoc ] dummyLoc ]


errorMessage3Part : Int -> String -> String -> String -> List Expr
errorMessage3Part lineNumber a b c =
    [ Expr "blue" [ Text a dummyLoc ] dummyLoc, Expr "blue" [ Text b dummyLoc ] dummyLoc, Expr "red" [ Text c dummyLoc ] dummyLoc ]


errorMessageInvisible : Int -> String -> Expr
errorMessageInvisible lineNumber message =
    Expr "red" [ Text message dummyLoc ] dummyLoc


errorMessage : String -> Expr
errorMessage message =
    Expr "red" [ Expr "underline" [ Text message dummyLoc ] dummyLoc ] dummyLoc


errorMessageBold : String -> Expr
errorMessageBold message =
    Expr "bold" [ Expr "red" [ Text message dummyLoc ] dummyLoc ] dummyLoc


errorMessage2 : String -> Expr
errorMessage2 message =
    Expr "blue" [ Text message dummyLoc ] dummyLoc


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
    case List.reverse state.stack of
        -- brackets with no intervening text
        (LB _) :: (RB meta) :: _ ->
            Loop
                { state
                    | committed = errorMessage "[?]" :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage state.lineNumber "Brackets need to enclose something" state.messages
                }

        -- consecutive left brackets
        (LB _) :: (LB meta) :: _ ->
            Loop
                { state
                    | committed = errorMessage "[" :: state.committed
                    , stack = []
                    , tokenIndex = meta.index
                    , messages = Helpers.prependMessage state.lineNumber "You have consecutive left brackets" state.messages
                }

        -- missing right bracket // OK
        (LB _) :: (S fName meta) :: rest ->
            Loop
                { state
                    | committed = errorMessage (errorSuffix rest) :: errorMessage2 ("[" ++ fName) :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage state.lineNumber "Missing right bracket" state.messages
                }

        -- space after left bracket // OK
        (LB _) :: (W " " meta) :: _ ->
            Loop
                { state
                    | committed = errorMessage "[ - can't have space after the bracket " :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage state.lineNumber "Can't have space after left bracket - try [something ..." state.messages
                }

        -- left bracket with nothing after it.  // OK
        (LB _) :: [] ->
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
            recoverFromError1 state


errorSuffix rest =
    case rest of
        [] ->
            "]?"

        (W _ _) :: [] ->
            "]?"

        _ ->
            ""


recoverFromError1 : State -> Step State State
recoverFromError1 state =
    let
        k =
            Symbol.balance <| Symbol.convertTokens (List.reverse state.stack)

        newStack =
            List.repeat k (RB dummyLoc) ++ state.stack

        newSymbols =
            Symbol.convertTokens (List.reverse newStack)

        reducible =
            M.reducible newSymbols
    in
    if reducible then
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



-- LOOP
