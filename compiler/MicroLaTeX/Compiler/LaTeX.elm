module MicroLaTeX.Compiler.LaTeX exposing (ordinaryBlock, transform)

import Compiler.ASTTools
import Either exposing (Either(..))
import Maybe.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))


ordinaryBlock name args exprs data m1 =
    ExpressionBlock
        { data
            | blockType = OrdinaryBlock (List.drop 1 args)
            , content = Right exprs
            , args = args
            , name = name
        }


transform1 =
    identity


{-| The role of function transform is to map a paragraph block
containing a single expression of designated name to
an ordinary block with designated arguments
-}
transform : ExpressionBlock -> ExpressionBlock
transform ((ExpressionBlock data) as block) =
    let
        normalized : Either String (List Expr)
        normalized =
            Compiler.ASTTools.normalize data.content
    in
    case normalized of
        Right ((Expr "bibitem" exprs m2) :: _) ->
            let
                content : List Expr
                content =
                    case Either.mapRight (List.drop 1) normalized of
                        Right val ->
                            val

                        Left _ ->
                            []

                args =
                    List.map Compiler.ASTTools.getText (List.take 2 exprs) |> Maybe.Extra.values
            in
            ordinaryBlock (Just "bibitem") args content data m2

        _ ->
            block |> Debug.log "ESCAPE (2)"
