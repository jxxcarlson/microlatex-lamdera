module Evergreen.V505.User exposing (..)

import BoundedDeque
import Evergreen.V505.Chat.Message
import Evergreen.V505.Document
import Evergreen.V505.Parser.Language
import Set
import Time


type alias Preferences =
    { language : Evergreen.V505.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V505.Document.DocumentInfo
    , preferences : Preferences
    , chatGroups : List String
    , sharedDocuments :
        List
            { title : String
            , id : String
            , owner : String
            }
    , sharedDocumentAuthors : Set.Set String
    , pings : List Evergreen.V505.Chat.Message.ChatMessage
    }
