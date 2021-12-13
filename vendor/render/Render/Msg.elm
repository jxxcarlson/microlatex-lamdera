module Render.Msg exposing (MarkupMsg(..))


type MarkupMsg
    = SendMeta { begin : Int, end : Int, index : Int }
    | SendId String
    | GetPublicDocument String
