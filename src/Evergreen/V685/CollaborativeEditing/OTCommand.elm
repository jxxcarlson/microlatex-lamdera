module Evergreen.V685.CollaborativeEditing.OTCommand exposing (..)


type Command
    = CInsert Int String
    | CMoveCursor Int
    | CDelete Int Int
    | CNoOp
