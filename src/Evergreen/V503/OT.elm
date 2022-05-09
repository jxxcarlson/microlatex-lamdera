module Evergreen.V503.OT exposing (..)


type Operation
    = Insert String
    | Delete Int
    | Skip Int


type alias Document =
    { id : String
    , cursor : Int
    , x : Int
    , y : Int
    , content : String
    }
