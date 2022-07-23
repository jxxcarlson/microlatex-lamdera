module Render.Text exposing (fromExpr, idem, print)

import L0.Parser.Error
import L0.Parser.Expression as Expression
import Parser.Expr exposing (Expr(..))


idem : String -> String
idem str =
    str
        |> Expression.parse 0
        |> print


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
