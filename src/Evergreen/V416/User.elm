module Evergreen.V416.User exposing (..)

import BoundedDeque
import Evergreen.V416.Document
import Evergreen.V416.Parser.Language
import Set
import Time


type alias Preferences =
    { language : Evergreen.V416.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V416.Document.DocumentInfo
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
