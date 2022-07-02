module Evergreen.V683.CollaborativeEditing.OTCommand exposing (..)


type Command
    = CInsert Int String
    | CMoveCursor Int
    | CDelete Int Int
    | CNoOp
