module Evergreen.V205.User exposing (..)

import BoundedDeque
import Evergreen.V205.Document
import Evergreen.V205.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V205.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V205.Document.DocumentInfo
    , preferences : Preferences
    }
