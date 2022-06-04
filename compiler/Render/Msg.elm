module Render.Msg exposing (Handling(..), MarkupMsg(..), SolutionState(..))


type MarkupMsg
    = SendMeta { begin : Int, end : Int, index : Int, id : String }
    | SendId String
    | SelectId String
    | GetPublicDocument String
    | GetPublicDocumentFromAuthor Handling String String
    | ProposeSolution SolutionState


type Handling
    = MHStandard
    | MHAsCheatSheet


type SolutionState
    = Unsolved
    | Solved String -- Solved SolutionId
