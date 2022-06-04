module Evergreen.V555.Render.Msg exposing (..)


type Handling
    = MHStandard
    | MHAsCheatSheet


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
    | GetPublicDocumentFromAuthor Handling String String
    | ProposeSolution SolutionState
