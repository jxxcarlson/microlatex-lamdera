module OT exposing (Document, Operation(..), apply, emptyDoc, findOps, reconcile, updateXY)

import Document


type Operation
    = Insert String
    | Delete Int
    | Skip Int


type alias Document =
    { cursor : Int, x : Int, y : Int, content : String }


emptyDoc =
    { cursor = 0, x = 0, y = 0, content = "" }


reconcile : Document -> Document -> Document
reconcile a b =
    let
        ops_ =
            findOps a b |> Debug.log "OPS"
    in
    apply ops_ a


findOps : Document -> Document -> List Operation
findOps before after =
    if after.content == before.content then
        [ Skip (after.cursor - before.cursor) ]

    else if after.cursor > before.cursor then
        [ Insert (String.slice before.cursor after.cursor after.content) ]

    else if after.cursor < before.cursor then
        [ Skip (after.cursor - before.cursor), Delete (before.cursor - after.cursor) ]

    else
        [ Delete (String.length before.content - String.length after.content) ]


applyOp : Operation -> Document -> Document
applyOp op { cursor, x, y, content } =
    -- TODO: fix x and y
    case op of
        Insert str ->
            { x = x + String.length str, y = y, cursor = cursor + String.length str, content = String.left cursor content ++ str ++ String.dropLeft cursor content }

        Delete n ->
            { x = x, y = y, cursor = cursor, content = String.left cursor content ++ String.dropLeft n (String.dropLeft cursor content) }

        Skip n ->
            { x = x + n, y = y, cursor = cursor + n, content = content }


updateXY : Document -> Document
updateXY doc =
    let
        newLocation =
            Document.location doc.cursor doc.content
    in
    { doc | x = newLocation.x, y = newLocation.y }


apply : List Operation -> Document -> Document
apply ops document =
    List.foldl applyOp document ops
