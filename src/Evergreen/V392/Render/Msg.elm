module Evergreen.V392.Render.Msg exposing (..)


type MarkupMsg
    = SendMeta
        { begin : Int
        , end : Int
        , index : Int
        , id : String
        }
    | SendId String
    | SelectId String
    | GetPublicDocument String
