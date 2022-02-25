module Compiler.LaTeX exposing (..)

import Either exposing (Either(..))
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))


b =
    ExpressionBlock { args = [], blockType = Paragraph, children = [], content = Right [ Expr "title" [ Text "foo" { begin = 7, end = 9, index = 3 } ] { begin = 0, end = 0, index = 0 } ], id = "0", indent = 1, lineNumber = 0, messages = [], name = Nothing, numberOfLines = 1, sourceText = "\\title{foo}" }


ordinaryBlock args str data m1 =
    ExpressionBlock
        { data
            | blockType = OrdinaryBlock args
            , content = Right [ Text str m1 ]
            , args = List.drop 1 args
            , name = List.head args
        }


transform : ExpressionBlock -> ExpressionBlock
transform ((ExpressionBlock data) as block) =
    case data.content of
        --Right [ Expr "title" [ Text str m1 ] m2 ] ->
        --    ordinaryBlock "title" str data m1
        Right [ _, Expr "section" [ Text str m1 ] m2 ] ->
            ordinaryBlock [ "heading", "1" ] str data m1

        Right [ _, Expr "subsection" [ Text str m1 ] m2 ] ->
            ordinaryBlock [ "heading", "2" ] str data m1

        Right [ _, Expr "subsubsection" [ Text str m1 ] m2 ] ->
            ordinaryBlock [ "heading", "3" ] str data m1

        Right [ _, Expr "subheading" [ Text str m1 ] m2 ] ->
            ordinaryBlock [ "heading", "4" ] str data m1

        Right [ _, Expr "makeTableOfContents" [] m2 ] ->
            ordinaryBlock [ "makeTableOfContents" ] "" data m2

        _ ->
            block
