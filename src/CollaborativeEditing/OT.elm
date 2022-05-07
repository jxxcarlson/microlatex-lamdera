module CollaborativeEditing.OT exposing
    ( Document
    , Operation(..)
    , apply
    , emptyDoc
    , encodeOperation
    , findOps
    , reconcile
    )

import Json.Encode as E


type alias Document =
    { id : String, cursor : Int, content : String }


type alias Cursor =
    Int


type Operation
    = Insert Cursor String
    | Delete Cursor Int
    | MoveCursor Cursor


encodeOperation : Operation -> E.Value
encodeOperation op =
    case op of
        Insert cursor str ->
            E.object [ ( "op", E.string "insert" ), ( "cursor", E.int cursor ), ( "strval", E.string str ) ]

        Delete cursor k ->
            E.object [ ( "op", E.string "delete" ), ( "cursor", E.int cursor ), ( "intval", E.int k ) ]

        MoveCursor cursor ->
            E.object [ ( "op", E.string "movecursor" ), ( "cursor", E.int cursor ) ]


emptyDoc =
    { id = "no-id", cursor = 0, content = "" }


reconcile : Document -> Document -> Document
reconcile a b =
    let
        ops_ =
            findOps a b
    in
    apply ops_ a


findOps : Document -> Document -> List Operation
findOps before after =
    if before.content == after.content then
        [ MoveCursor (after.cursor - before.cursor) ]

    else if after.cursor > before.cursor then
        [ Insert before.cursor (String.slice before.cursor after.cursor after.content) ]

    else if after.cursor == before.cursor then
        let
            tailAfter =
                String.dropLeft after.cursor after.content

            tailBefore =
                String.dropLeft before.cursor before.content

            n =
                String.length tailBefore - String.length tailAfter
        in
        [ Delete after.cursor n ]

    else if after.cursor < before.cursor then
        let
            tailAfter =
                String.dropLeft after.cursor after.content

            tailBefore =
                String.dropLeft before.cursor before.content

            n =
                String.length tailBefore - String.length tailAfter
        in
        [ Delete before.cursor n ]

    else
        []


applyOp : Operation -> Document -> Document
applyOp op doc =
    case op of
        Insert cursor str ->
            { id = doc.id
            , cursor = Debug.log "CURSOR" cursor + String.length str
            , content = (String.left cursor doc.content |> Debug.log "LEFT") ++ str ++ (String.dropLeft cursor doc.content |> Debug.log "RIGHT")
            }

        Delete cursor n ->
            { id = doc.id
            , cursor = cursor - 1
            , content = String.left cursor doc.content ++ String.dropLeft n (String.dropLeft cursor doc.content)
            }

        MoveCursor cursor ->
            { id = doc.id
            , cursor = cursor
            , content = doc.content
            }


apply : List Operation -> Document -> Document
apply ops document =
    List.foldl applyOp document ops
