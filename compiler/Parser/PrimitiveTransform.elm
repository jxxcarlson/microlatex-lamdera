module Parser.PrimitiveTransform exposing (transform)

import Parser.Language exposing (Language(..))
import Parser.Line exposing (PrimitiveBlockType(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)


transform : Language -> PrimitiveBlock -> PrimitiveBlock
transform lang block =
    case lang of
        L0Lang ->
            block

        MicroLaTeXLang ->
            transformMiniLaTeX block


transformMiniLaTeX : PrimitiveBlock -> PrimitiveBlock
transformMiniLaTeX block =
    let
        normalizedContent =
            block.content |> List.map (String.dropLeft block.indent) |> normalize
    in
    case normalizedContent of
        "\\item" :: rest ->
            { block | content = "| item" :: rest, name = Just "item", blockType = PBOrdinary } |> Debug.log "DP, TRANSF, PRIM"

        "\\numbered" :: rest ->
            { block | content = "| numbered" :: rest, name = Just "numbered", blockType = PBOrdinary } |> Debug.log "DP, TRANSF, PRIM"

        _ ->
            block |> Debug.log "DP, TRANSF, ESC"


normalize : List String -> List String
normalize list =
    case list of
        "" :: rest ->
            rest

        _ ->
            list
