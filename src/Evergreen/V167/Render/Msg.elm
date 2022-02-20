module Evergreen.V167.Render.Msg exposing (..)


type L0Msg
    = SendMeta
        { begin : Int
        , end : Int
        , index : Int
        }
    | SendId String
    | GetPublicDocument String
