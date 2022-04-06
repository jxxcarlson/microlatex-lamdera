module Evergreen.V269.UserMessage exposing (..)


type alias UserMessage =
    { from : String
    , to : String
    , subject : String
    , content : String
    }
