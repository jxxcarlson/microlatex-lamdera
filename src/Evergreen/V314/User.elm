module Evergreen.V314.User exposing (..)

import BoundedDeque
import Evergreen.V314.Document
import Evergreen.V314.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V314.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V314.Document.DocumentInfo
    , preferences : Preferences
    }
