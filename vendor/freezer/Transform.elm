module L0.Transform exposing (transform)

import Compiler.ASTTools
import Compiler.Util
import Either exposing (Either(..))
import Maybe.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))
import Parser.Language exposing (Language(..))
import Parser.Meta exposing (Meta)


ordinaryBlock args exprs data m1 =
    ExpressionBlock
        { data
            | blockType = OrdinaryBlock args
            , content = Right exprs
            , args = List.drop 1 args
            , name = List.head args
        }


splitString splitter str =
    if String.contains splitter str then
        String.split splitter str |> List.map String.trim

    else
        String.words str


splitExprList : List Expr -> List Expr
splitExprList exprs =
    let
        exprs_ : List ( List String, Meta )
        exprs_ =
            List.map splitExpr exprs

        --m =
        --    List.head exprs_ |> Maybe.map Tuple.second |> Maybe.withDefault { begin = 0, end = 0, index = 0 }
        --
        --strs : List String
        --strs =
        --    List.map Tuple.first exprs_ |> List.concat
    in
    List.map (\( strings, m_ ) -> List.map (\s -> Text s m_) strings) exprs_ |> List.concat


splitExpr : Expr -> ( List String, Meta )
splitExpr expr =
    case expr of
        Text str m ->
            ( splitString "," str, m )

        _ ->
            ( [], { begin = 0, end = 0, index = 0 } )


{-| The role of function transform is to map a paragraph block
containing a single expression of designated name to
an ordinary block with designated arguments
-}
transform : ExpressionBlock -> ExpressionBlock
transform ((ExpressionBlock data) as block) =
    let

        normalized : Either String (List Expr)
        normalized =
            case data.content of
                Right ((Text _ _) :: rest) ->
                    Right rest

                _ ->
                    data.content

        expressions : List Expr
        expressions =
            (case normalized of
                Right exprs ->
                    splitExprList exprs

                _ ->
                    []
            )


        args : List String
        args =
            expressions |> List.map Compiler.ASTTools.getText |> Maybe.Extra.values
    in
    case normalized of
        Right [ Expr "bibitem" exprs m2, _ ] ->
            ordinaryBlock ("bibitem" :: (args |> List.take 2)) ((expressions |> List.drop 2) data m2)

        _ ->
            block
