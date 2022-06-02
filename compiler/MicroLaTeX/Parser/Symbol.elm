module MicroLaTeX.Parser.Symbol exposing (Symbol(..), balance, convertTokens, convertTokens2, toString, value)

import Maybe.Extra
import MicroLaTeX.Parser.Token exposing (Token(..))


type Symbol
    = B
    | L
    | R
    | O
    | M
    | LM
    | RM
    | C


value : Symbol -> Int
value symbol =
    case symbol of
        B ->
            0

        L ->
            1

        R ->
            -1

        O ->
            0

        M ->
            0

        RM ->
            1

        LM ->
            -1

        C ->
            0


balance : List Symbol -> Int
balance symbols =
    symbols |> List.map value |> List.sum


symbolToString : Symbol -> String
symbolToString symbol =
    case symbol of
        B ->
            "B"

        L ->
            "L"

        R ->
            "R"

        O ->
            "O"

        M ->
            "M"

        LM ->
            "LM"

        RM ->
            "RM"

        C ->
            "C"


toString : List Symbol -> String
toString symbols =
    List.map symbolToString symbols |> String.join " "


convertTokens : List Token -> List Symbol
convertTokens tokens =
    List.map toSymbol tokens |> Maybe.Extra.values


convertTokens2 : List Token -> List Symbol
convertTokens2 tokens =
    List.map toSymbol2 tokens


toSymbol : Token -> Maybe Symbol
toSymbol token =
    case token of
        BS _ ->
            Just B

        LB _ ->
            Just L

        RB _ ->
            Just R

        MathToken _ ->
            Just M

        LMathBracket _ ->
            Just LM

        RMathBracket _ ->
            Just RM

        CodeToken _ ->
            Just C

        _ ->
            Nothing


toSymbol2 : Token -> Symbol
toSymbol2 token =
    case token of
        LB _ ->
            L

        RB _ ->
            R

        MathToken _ ->
            M

        LMathBracket _ ->
            LM

        RMathBracket _ ->
            RM

        CodeToken _ ->
            C

        _ ->
            O
