module MicroLaTeX.Compiler.LaTeX exposing (..)

import Compiler.Util
import Either exposing (Either(..))
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))
import Parser.Language exposing (Language(..))


ordinaryBlock args exprs data m1 =
    ExpressionBlock
        { data
            | blockType = OrdinaryBlock args
            , content = Right exprs
            , args = List.drop 1 args
            , name = List.head args
        }


transform : ExpressionBlock Expr -> ExpressionBlock Expr
transform ((ExpressionBlock data) as block) =
    case data.content of
        --Right [ Expr "title" [ Text str m1 ] m2 ] ->
        --    ordinaryBlock "title" str data m1
        Right [ _, Expr "section" exprs m2 ] ->
            ordinaryBlock [ "section", "1" ] exprs data m2

        Right [ _, Expr "subsection" exprs m2 ] ->
            ordinaryBlock [ "section", "2" ] exprs data m2

        Right [ _, Expr "subsubsection" exprs m2 ] ->
            ordinaryBlock [ "section", "3" ] exprs data m2

        Right [ _, Expr "subheading" exprs m2 ] ->
            ordinaryBlock [ "section", "4" ] exprs data m2

        Right [ _, Expr "makeTableOfContents" [] m2 ] ->
            ordinaryBlock [ "makeTableOfContents" ] [] data m2

        _ ->
            block
