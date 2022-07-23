module L0.Test exposing
    ( check1
    , check2
    , checkErrorHandling
    , p
    , pp
    , print
    )

import L0.Parser.Expression as Expression
import Parser.Expr exposing (Expr(..))


check1 : String -> Result String String
check1 str =
    let
        str2 =
            pp str
    in
    case str == str2 of
        True ->
            Ok str

        False ->
            Err str2


checkErrorHandling : String -> String -> Result String String
checkErrorHandling input output =
    let
        str2 =
            pp input
    in
    case output == str2 of
        True ->
            Ok output

        False ->
            Err str2


check2 : String -> Result (List Expr) String
check2 str =
    let
        e1 =
            p str

        e2 =
            ppp str
    in
    case e1 == e2 of
        True ->
            Ok str

        False ->
            Err e2


p : String -> List Expr
p str =
    Expression.parse 0 str


pp : String -> String
pp str =
    str
        |> Expression.parse 0
        |> print


ppp : String -> List Expr
ppp str =
    str |> p |> print |> p


print : List Expr -> String
print expressions =
    List.map fromExpr expressions |> String.join ""


fromExpr : Expr -> String
fromExpr expr =
    case expr of
        Expr name expressions _ ->
            "[" ++ name ++ (List.map fromExpr expressions |> String.join "") ++ "]"

        Text str _ ->
            str

        Verbatim name str _ ->
            case name of
                "math" ->
                    "$" ++ str ++ "$"

                "code" ->
                    "`" ++ str ++ "`"

                _ ->
                    "error: verbatim " ++ name ++ " not recognized"
