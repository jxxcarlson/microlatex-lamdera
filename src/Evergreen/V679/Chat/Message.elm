module Evergreen.V679.Chat.Message exposing (..)

import Effect.Time


type alias ChatMessage =
    { sender : String
    , group : String
    , subject : String
    , content : String
    , date : Effect.Time.Posix
    }
