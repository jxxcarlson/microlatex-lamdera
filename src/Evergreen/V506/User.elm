module Evergreen.V506.User exposing (..)

import BoundedDeque
import Evergreen.V506.Chat.Message
import Evergreen.V506.Document
import Evergreen.V506.Parser.Language
import Set
import Time


type alias Preferences =
    { language : Evergreen.V506.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V506.Document.DocumentInfo
    , preferences : Preferences
    , chatGroups : List String
    , sharedDocuments :
        List
            { title : String
            , id : String
            , owner : String
            }
    , sharedDocumentAuthors : Set.Set String
    , pings : List Evergreen.V506.Chat.Message.ChatMessage
    }
