module Evergreen.V409.User exposing (..)

import BoundedDeque
import Evergreen.V409.Document
import Evergreen.V409.Parser.Language
import Set
import Time


type alias Preferences =
    { language : Evergreen.V409.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V409.Document.DocumentInfo
    , preferences : Preferences
    , chatGroups : List String
    , sharedDocuments :
        List
            { title : String
            , id : String
            , owner : String
            }
    , sharedDocumentAuthors : Set.Set String
    }
