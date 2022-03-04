module Evergreen.V59.Render.Msg exposing (..)


type L0Msg
    = SendMeta
        { begin : Int
        , end : Int
        , index : Int
        }
    | SendId String
    | SelectId String
    | GetPublicDocument String
