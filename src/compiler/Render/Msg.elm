module Render.Msg exposing (L0Msg(..))


type L0Msg
    = SendMeta { begin : Int, end : Int, index : Int }
    | SendId String
    | SelectId String
    | GetPublicDocument String
