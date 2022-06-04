module Evergreen.V555.CollaborativeEditing.OT exposing (..)


type alias Cursor =
    Int


type Operation
    = Insert Cursor String
    | Delete Cursor Int
    | MoveCursor Cursor
    | OTNoOp


type alias Document =
    { docId : String
    , cursor : Int
    , content : String
    }
