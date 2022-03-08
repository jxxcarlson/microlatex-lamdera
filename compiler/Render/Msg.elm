module Render.Msg exposing (MarkupMsg(..))


type MarkupMsg
    = SendMeta { begin : Int, end : Int, index : Int, id : String }
    | SendId String
    | SelectId String
    | GetPublicDocument String
