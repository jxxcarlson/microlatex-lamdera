module Evergreen.V502.Chat.Message exposing (..)

import Time


type alias ChatMessage =
    { sender : String
    , group : String
    , subject : String
    , content : String
    , date : Time.Posix
    }
