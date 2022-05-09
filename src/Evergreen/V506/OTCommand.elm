module Evergreen.V506.OTCommand exposing (..)


type Command
    = CInsert Int String
    | CSkip Int Int
    | CDelete Int Int
