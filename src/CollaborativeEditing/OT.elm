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
    { id : String, cursor : Int, x : Int, y : Int, content : String }


type Operation
    = Insert String
    | Delete Int
    | MoveCursor Int
    | OTNoOp


encodeOperation : Operation -> E.Value
encodeOperation op =
    case op of
        Insert str ->
            E.object [ ( "op", E.string "insert" ), ( "strval", E.string str ) ]

        Delete k ->
            E.object [ ( "op", E.string "delete" ), ( "intval", E.int k ) ]

        MoveCursor k ->
            E.object [ ( "op", E.string "movecursor" ), ( "intval", E.int k ) ]

        OTNoOp ->
            E.object [ ( "op", E.string "otnoop" ), ( "intval", E.int 0 ) ]


emptyDoc =
    { id = "no-id", cursor = 0, x = 0, y = 0, content = "" }


reconcile : Document -> Document -> Document
reconcile a b =
    let
        ops_ =
            findOps a b
    in
    apply ops_ a


findOps : Document -> Document -> List Operation
findOps before after =
    -- No Change of content
    if after.content == before.content then
        [ MoveCursor (after.cursor - before.cursor) ]
        -- From here on, we know that there is change of content

    else if after.cursor > before.cursor then
        [ Insert (String.slice before.cursor after.cursor after.content) ]

    else if after.cursor < before.cursor then
        [ MoveCursor (after.cursor - before.cursor + 1), Delete (before.cursor - after.cursor) ]

    else
        [ Delete (String.length before.content - String.length after.content) ]


applyOp : Operation -> Document -> Document
applyOp op { id, cursor, x, y, content } =
    case op of
        Insert str ->
            { id = id
            , x = x + String.length str
            , y = y
            , cursor = cursor + String.length str
            , content = String.left cursor content ++ str ++ String.dropLeft cursor content
            }

        Delete n ->
            if cursor == String.length content - 1 then
                { id = id
                , x = x - 1
                , y = y
                , cursor = cursor - 1
                , content = String.left cursor content ++ String.dropLeft n (String.dropLeft cursor content)
                }

            else
                { id = id
                , x = x
                , y = y
                , cursor = cursor
                , content = String.left cursor content ++ String.dropLeft n (String.dropLeft cursor content)
                }

        MoveCursor n ->
            { id = id
            , x = x + n
            , y = y
            , cursor = cursor + n
            , content = content
            }

        OTNoOp ->
            { id = id
            , x = x
            , y = y
            , cursor = cursor
            , content = content
            }


apply : List Operation -> Document -> Document
apply ops document =
    List.foldl applyOp document ops
