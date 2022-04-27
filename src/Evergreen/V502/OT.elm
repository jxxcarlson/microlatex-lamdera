module Evergreen.V502.OT exposing (..)


type alias Document =
    { cursor : Int
    , x : Int
    , y : Int
    , content : String
    }


type Operation
    = Insert String
    | Delete Int
    | Skip Int
