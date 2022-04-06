module Evergreen.V269.User exposing (..)

import BoundedDeque
import Evergreen.V269.Document
import Evergreen.V269.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V269.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V269.Document.DocumentInfo
    , preferences : Preferences
    }
