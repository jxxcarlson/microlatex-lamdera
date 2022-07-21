module Evergreen.V718.CollaborativeEditing.OTCommand exposing (..)


type Command
    = CInsert Int String
    | CMoveCursor Int
    | CDelete Int Int
    | CNoOp
