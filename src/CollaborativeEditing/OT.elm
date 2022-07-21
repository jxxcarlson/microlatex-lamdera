module CollaborativeEditing.OT exposing
    ( Document
    , Operation(..)
    , apply
    , applyOp
    , emptyDoc
    , encodeOperation
    ,  findOp
       --, reconcile

    , toString
    )

import Json.Encode as E


type alias Document =
    { docId : String, cursor : Int, content : String }


type alias Cursor =
    Int


type Operation
    = Insert Cursor String
    | Delete Cursor Int
    | MoveCursor Cursor
    | OTNoOp


toString : Operation -> String
toString op =
    case op of
        Insert cursor str ->
            "INS " ++ String.fromInt cursor ++ " " ++ str

        Delete cursor k ->
            "DEL " ++ String.fromInt cursor ++ " " ++ String.fromInt k

        MoveCursor cursor ->
            "MOV " ++ String.fromInt cursor

        OTNoOp ->
            "NOP"


encodeOperation : Operation -> E.Value
encodeOperation op =
    case op of
        Insert cursor str ->
            E.object [ ( "op", E.string "insert" ), ( "cursor", E.int cursor ), ( "strval", E.string str ) ]

        Delete cursor k ->
            E.object [ ( "op", E.string "delete" ), ( "cursor", E.int cursor ), ( "intval", E.int k ) ]

        MoveCursor cursor ->
            E.object [ ( "op", E.string "movecursor" ), ( "cursor", E.int cursor ) ]

        OTNoOp ->
            E.object [ ( "op", E.string "noop" ) ]


emptyDoc =
    { id = "no-id", cursor = 0, content = "" }


findOp : Document -> Document -> Operation
findOp before after =
    if before.content == after.content then
        MoveCursor (after.cursor - before.cursor)

    else if after.cursor > before.cursor then
        Insert before.cursor (String.slice before.cursor after.cursor after.content)

    else if after.cursor == before.cursor then
        let
            tailAfter =
                String.dropLeft after.cursor after.content

            tailBefore =
                String.dropLeft before.cursor before.content

            n =
                String.length tailBefore - String.length tailAfter
        in
        Delete after.cursor n

    else if after.cursor < before.cursor then
        let
            headAfter =
                String.left after.cursor after.content

            headBefore =
                String.left before.cursor before.content

            n =
                String.length headAfter - String.length headBefore
        in
        Delete before.cursor n

    else
        OTNoOp


applyOp : Operation -> Document -> Document
applyOp op doc =
    case op of
        Insert cursor str ->
            { docId = doc.docId
            , cursor = cursor + String.length str
            , content = String.left cursor doc.content ++ str ++ String.dropLeft cursor doc.content
            }

        Delete cursor n ->
            if n >= 0 then
                { docId = doc.docId
                , cursor = cursor - 1
                , content = String.left cursor doc.content ++ String.dropLeft n (String.dropLeft cursor doc.content)
                }

            else
                { docId = doc.docId
                , cursor = cursor + n
                , content =
                    (doc.content |> String.left cursor |> String.dropRight -n)
                        ++ String.dropLeft cursor doc.content
                }

        MoveCursor cursor ->
            { docId = doc.docId
            , cursor = cursor
            , content = doc.content
            }

        OTNoOp ->
            { docId = doc.docId
            , cursor = doc.cursor
            , content = doc.content
            }


apply : List Operation -> Document -> Document
apply ops document =
    List.foldl applyOp document ops
