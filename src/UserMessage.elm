module UserMessage exposing (UserMessage)


type alias UserMessage =
    { from : String
    , to : String
    , subject : String
    , content : String
    }
