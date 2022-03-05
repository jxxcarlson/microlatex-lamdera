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
        _ =
            Debug.log "CONT (0)" data.content

        normalize : Either String (List Expr) -> Either String (List Expr)
        normalize exprs =
            (case exprs of
                Right ((Text _ _) :: rest) ->
                    Right rest

                _ ->
                    data.content
            )
                |> Debug.log "NORMALIZED"

        normalizeExprs : List Expr -> List Expr
        normalizeExprs exprs =
            case exprs of
                (Text _ _) :: rest ->
                    rest

                _ ->
                    exprs

        normalized =
            normalize data.content
    in
    case normalized of
        Right [ Expr "title" exprs m2 ] ->
            ordinaryBlock [ "title" ] exprs data m2

        Right [ Expr "bibitem" exprs m2, _ ] ->
            let
                _ =
                    Debug.log "HI THERE" 0

                content : List Expr
                content =
                    case Either.mapRight (List.drop 1) normalized of
                        Right val ->
                            let
                                _ =
                                    normalizeExprs val |> Debug.log "VAL, NORMALIZED"
                            in
                            val |> Debug.log "TR, VAL (content)s"

                        Left _ ->
                            [] |> Debug.log "EMPTY"

                args =
                    List.map Compiler.ASTTools.getText (List.take 2 exprs) |> Maybe.Extra.values |> Debug.log "TR, ARGS"
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
            block |> Debug.log "DEFAULT"
