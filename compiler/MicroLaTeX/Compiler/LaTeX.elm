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


{-| The role of function transform is to map a paragraph block
containing a single expression of designated name to
an ordinary block with designated arguments
-}
transform : ExpressionBlock -> ExpressionBlock
transform ((ExpressionBlock data) as block) =
    let
        normalize : Either String (List Expr) -> Either String (List Expr)
        normalize exprs =
            case exprs of
                Right ((Text _ _) :: rest) ->
                    Right rest

                _ ->
                    data.content

        normalized =
            normalize data.content
    in
    case normalized of
        Right [ Expr "title" exprs m2 ] ->
            ordinaryBlock (Just "title") data.args exprs data m2

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
            ordinaryBlock (Just "bibitem") data.args content data m2

        Right [ Expr "setcounter" exprs m2 ] ->
            ordinaryBlock (Just "setcounter") data.args exprs data m2

        Right [ Expr "section" exprs m2 ] ->
            ordinaryBlock (Just "section") [ "1" ] exprs data m2

        Right [ Expr "subsection" exprs m2 ] ->
            ordinaryBlock (Just "section") [ "2" ] exprs data m2

        Right [ Expr "subsubsection" exprs m2 ] ->
            ordinaryBlock (Just "section") [ "3" ] exprs data m2

        Right [ Expr "subheading" exprs m2 ] ->
            ordinaryBlock (Just "section") [ "4" ] exprs data m2

        Right [ Expr "contents" [] m2 ] ->
            ordinaryBlock (Just "contents") data.args [] data m2

        _ ->
            block
