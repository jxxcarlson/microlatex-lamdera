module Evergreen.V718.User exposing (..)

import BoundedDeque
import Effect.Time
import Evergreen.V718.Chat.Message
import Evergreen.V718.Document
import Evergreen.V718.Parser.Language
import Set


type alias Preferences =
    { language : Evergreen.V718.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Effect.Time.Posix
    , modified : Effect.Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V718.Document.DocumentInfo
    , preferences : Preferences
    , chatGroups : List String
    , sharedDocuments :
        List
            { title : String
            , id : String
            , owner : String
            }
    , sharedDocumentAuthors : Set.Set String
    , pings : List Evergreen.V718.Chat.Message.ChatMessage
    }
