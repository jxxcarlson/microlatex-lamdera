module Evergreen.V557.CollaborativeEditing.OTCommand exposing (..)


type Command
    = CInsert Int String
    | CMoveCursor Int Int
    | CDelete Int Int
    | CNoOp Int
