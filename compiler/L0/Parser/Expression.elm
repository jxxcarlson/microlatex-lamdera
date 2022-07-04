module L0.Parser.Expression exposing
    ( State
    , extractMessages
    , parse
    , parseToState
    , parseTokenList
    )

import L0.Parser.Match as M
import L0.Parser.Symbol as Symbol exposing (Symbol(..))
import L0.Parser.Token as Token exposing (Token(..), TokenType(..))
import List.Extra
import Parser.Expr exposing (Expr(..))
import Parser.Helpers as Helpers exposing (Step(..), loop)



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


makeId : Int -> Int -> String
makeId a b =
    String.fromInt a ++ "." ++ String.fromInt b


makeIdFromState : State -> String
makeIdFromState state =
    String.fromInt state.lineNumber ++ "." ++ String.fromInt state.tokenIndex


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
            parseToState lineNumber str
    in
    ( state.committed, state.messages |> Debug.log "Messages (3)" )


parseToState : Int -> String -> State
parseToState lineNumber str =
    str
        |> Token.run
        |> parseTokenListToState lineNumber



-- PARSER


parseTokenListToState : Int -> List Token -> State
parseTokenListToState lineNumber tokens =
    let
        state =
            tokens |> initWithTokens lineNumber |> run

        _ =
            Debug.log "MESSAGES (STATE)" (extractMessages state)
    in
    state


parseTokenList : Int -> List Token -> List Expr
parseTokenList lineNumber tokens =
    parseTokenListToState lineNumber tokens |> .committed


run : State -> State
run state =
    loop state nextStep
        |> (\state_ -> { state_ | committed = List.reverse state_.committed })


nextStep : State -> Step State State
nextStep state =
    case getToken state of
        Nothing ->
            if stackIsEmpty state then
                Done state

            else
                -- the stack is not empty, so we need to handle the parse error
                recoverFromError state

        Just token ->
            state
                |> advanceTokenIndex
                |> pushOrCommit token
                |> reduceState
                |> (\st -> { st | step = st.step + 1 })
                |> Loop


advanceTokenIndex : State -> State
advanceTokenIndex state =
    { state | tokenIndex = state.tokenIndex + 1 }


getToken : State -> Maybe Token
getToken state =
    List.Extra.getAt state.tokenIndex state.tokens


stackIsEmpty : State -> Bool
stackIsEmpty state =
    List.isEmpty state.stack



-- PUSH


pushOrCommit : Token -> State -> State
pushOrCommit token state =
    case token of
        S _ _ ->
            pushOrCommit_ token state

        W _ _ ->
            pushOrCommit_ token state

        MathToken _ ->
            pushOnStack token state

        CodeToken _ ->
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


pushOrCommit_ : Token -> State -> State
pushOrCommit_ token state =
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
            Just (Text str (boostMeta 0 (Token.indexOf token) loc))

        W str loc ->
            Just (Text str (boostMeta 0 (Token.indexOf token) loc))

        _ ->
            Nothing


push : Token -> State -> State
push token state =
    { state | stack = token :: state.stack }



-- REDUCE


reduceState : State -> State
reduceState state =
    let
        symbols =
            state.stack |> Symbol.convertTokens |> List.reverse |> Debug.log "SYMBOLS"
    in
    if M.reducible symbols then
        case List.head symbols of
            Just L ->
                case eval state.lineNumber (state.stack |> List.reverse) of
                    (Expr "invisible (1)" [ Text message _ ] _) :: rest ->
                        { state | stack = [], committed = rest ++ state.committed, messages = Helpers.prependMessage state.lineNumber message state.messages }

                    whatever ->
                        { state | stack = [], committed = whatever ++ state.committed }

            -- { state | stack = [], committed = eval (state.stack |> List.reverse) ++ state.committed }
            Just M ->
                { state
                    | stack = []
                    , committed =
                        Verbatim "math"
                            (Token.toString <|
                                unbracket <|
                                    List.reverse state.stack
                            )
                            { begin = 0, end = 0, index = 0, id = makeIdFromState state }
                            :: state.committed
                }

            Just C ->
                { state
                    | stack = []
                    , committed =
                        Verbatim "code"
                            (Token.toString <|
                                unbracket <|
                                    List.reverse state.stack
                            )
                            { begin = 0, end = 0, index = 0, id = makeIdFromState state }
                            :: state.committed
                }

            _ ->
                state

    else
        state


{-| remove first and last token
-}
unbracket : List a -> List a
unbracket list =
    List.drop 1 (List.take (List.length list - 1) list)


{-| areBracketed tokns == True iff tokens are derived from "[ ... ]"
-}
areBracketed : List Token -> Bool
areBracketed tokens =
    List.map Token.type_ (List.take 1 tokens)
        == [ TLB ]
        && List.map Token.type_ (List.take 1 (List.reverse tokens))
        == [ TRB ]


boostMeta : Int -> Int -> { begin : Int, end : Int, index : Int } -> { begin : Int, end : Int, index : Int, id : String }
boostMeta lineNumber tokenIndex { begin, end, index } =
    { begin = begin, end = end, index = index, id = makeId lineNumber tokenIndex }


eval : Int -> List Token -> List Expr
eval lineNumber tokens =
    if areBracketed tokens then
        let
            args =
                unbracket tokens |> Debug.log "ARGS"
        in
        case List.head args of
            -- The reversed token list is of the form [LB name EXPRS RB], so return [Expr name (evalList EXPRS)]
            Just (S name meta) ->
                [ Expr name (evalList lineNumber (List.drop 1 args)) (boostMeta lineNumber meta.index meta) ]

            Nothing ->
                -- this happens with input of "[]"
                [ errorMessage "[ ]" ]

            _ ->
                [ errorMessage "[••]" ]

    else
        []


evalList : Int -> List Token -> List Expr
evalList lineNumber tokens =
    case List.head tokens of
        Just token ->
            case Token.type_ token of
                TLB ->
                    case M.match (Symbol.convertTokens2 tokens) of
                        Nothing ->
                            [ errorMessageInvisible lineNumber "Error on match", Text "error on match" dummyLocWithId ]

                        Just k ->
                            let
                                ( a, b ) =
                                    M.splitAt (k + 1) tokens
                            in
                            eval lineNumber a ++ evalList lineNumber b

                _ ->
                    case exprOfToken token of
                        Just expr ->
                            expr :: evalList lineNumber (List.drop 1 tokens)

                        Nothing ->
                            [ errorMessage ("Line " ++ String.fromInt lineNumber ++ ", error converting token"), Text "error converting Token" dummyLocWithId ]

        _ ->
            []


errorMessageInvisible : Int -> String -> Expr
errorMessageInvisible lineNumber message =
    Expr "invisible" [ Text message dummyLocWithId ] dummyLocWithId


errorMessage : String -> Expr
errorMessage message =
    Expr "errorHighlight" [ Text message dummyLocWithId ] dummyLocWithId


addErrorMessage : String -> State -> State
addErrorMessage message state =
    let
        committed =
            errorMessage message :: state.committed
    in
    { state | committed = committed }


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
                    , messages = Helpers.prependMessage state.lineNumber "Brackets must enclose something" state.messages
                }

        -- consecutive left brackets
        (LB _) :: (LB meta) :: _ ->
            Loop
                { state
                    | committed = errorMessage "[@" :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage state.lineNumber "Consecutive left brackets" state.messages
                }

        -- missing right bracket // OK
        (LB _) :: (S fName meta) :: rest ->
            Loop
                { state
                    | committed = errorMessage (errorSuffix rest) :: errorMessage ("[" ++ fName) :: state.committed
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
                    | committed = errorMessage message :: state.committed
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


dummyLocWithId =
    { begin = 0, end = 0, index = dummyTokenIndex, id = "dummy (2)" }



-- LOOP
