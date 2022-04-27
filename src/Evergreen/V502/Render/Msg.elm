module Evergreen.V502.Render.Msg exposing (..)


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
    | GetPublicDocumentFromAuthor String String
    | ProposeSolution SolutionState
