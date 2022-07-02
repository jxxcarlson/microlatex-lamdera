module Evergreen.V685.User exposing (..)

import BoundedDeque
import Effect.Time
import Evergreen.V685.Chat.Message
import Evergreen.V685.Document
import Evergreen.V685.Parser.Language
import Set


type alias Preferences =
    { language : Evergreen.V685.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Effect.Time.Posix
    , modified : Effect.Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V685.Document.DocumentInfo
    , preferences : Preferences
    , chatGroups : List String
    , sharedDocuments :
        List
            { title : String
            , id : String
            , owner : String
            }
    , sharedDocumentAuthors : Set.Set String
    , pings : List Evergreen.V685.Chat.Message.ChatMessage
    }
