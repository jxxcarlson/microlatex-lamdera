module Render.Msg exposing (MarkupMsg(..), SolutionState(..))


type MarkupMsg
    = SendMeta { begin : Int, end : Int, index : Int, id : String }
    | SendId String
    | SelectId String
    | GetPublicDocument String
    | GetPublicDocumentFromAuthor String String
    | ProposeSolution SolutionState


type SolutionState
    = Unsolved
    | Solved String -- Solved SolutionId
