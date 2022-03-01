module MicroLaTeX.Compiler.LaTeX exposing (ordinaryBlock, transform)

import Compiler.ASTTools
import Either exposing (Either(..))
import Maybe.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))


ordinaryBlock args exprs data m1 =
    ExpressionBlock
        { data
            | blockType = OrdinaryBlock args
            , content = Right exprs
            , args = List.drop 1 args
            , name = List.head args
        }


{-| The role of function transform is to map a paragraph block
containing a single expression of designated name to
an ordinary block with designated arguments
-}
transform : ExpressionBlock Expr -> ExpressionBlock Expr
transform ((ExpressionBlock data) as block) =
    let
        normalized =
            case data.content of
                Right ((Text _ _) :: rest) ->
                    Right rest

                _ ->
                    data.content
    in
    case normalized of
        Right [ Expr "title" exprs m2 ] ->
            ordinaryBlock [ "title" ] exprs data m2

        Right [ Expr "bibitem" exprs m2, _ ] ->
            let
                content : List Expr
                content =
                    case Either.mapRight (List.drop 2) data.content of
                        Right val ->
                            val

                        Left _ ->
                            []

                args =
                    List.map Compiler.ASTTools.getText (List.take 2 exprs) |> Maybe.Extra.values
            in
            ordinaryBlock ("bibitem" :: args) content data m2

        Right [ Expr "section" exprs m2 ] ->
            ordinaryBlock [ "section", "1" ] exprs data m2

        Right [ Expr "subsection" exprs m2 ] ->
            ordinaryBlock [ "section", "2" ] exprs data m2

        Right [ Expr "subsubsection" exprs m2 ] ->
            ordinaryBlock [ "section", "3" ] exprs data m2

        Right [ Expr "subheading" exprs m2 ] ->
            ordinaryBlock [ "section", "4" ] exprs data m2

        Right [ Expr "contents" [] m2 ] ->
            ordinaryBlock [ "contents" ] [] data m2

        _ ->
            block
