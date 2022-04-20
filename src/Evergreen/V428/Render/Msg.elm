module Evergreen.V428.Render.Msg exposing (..)


type SolutionState
    = Unsolved
    | Solved String


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
    | ProposeSolution SolutionState
