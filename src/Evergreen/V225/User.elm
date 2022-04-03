module Evergreen.V225.User exposing (..)

import BoundedDeque
import Evergreen.V225.Document
import Evergreen.V225.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V225.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V225.Document.DocumentInfo
    , preferences : Preferences
    }
