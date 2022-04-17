module OT exposing (Document, Operation(..), apply, findOps, reconcile)


type Operation
    = Insert String
    | Delete Int
    | Skip Int


type alias Document =
    { cursor : Int, content : String }


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
        [ Skip (after.cursor - before.cursor), Insert (String.slice after.cursor before.cursor after.content) ]

    else
        [ Delete (String.length before.content - String.length after.content) ]


applyOp : Operation -> Document -> Document
applyOp op { cursor, content } =
    case op of
        Insert str ->
            { cursor = cursor + String.length str, content = String.left cursor content ++ str ++ String.dropLeft cursor content }

        Delete n ->
            { cursor = cursor, content = String.left cursor content ++ String.dropLeft n (String.dropLeft cursor content) }

        Skip n ->
            { cursor = cursor + n, content = content }


apply : List Operation -> Document -> Document
apply ops document =
    List.foldl applyOp document ops
