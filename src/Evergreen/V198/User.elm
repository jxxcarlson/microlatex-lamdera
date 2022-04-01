module Evergreen.V198.User exposing (..)

import BoundedDeque
import Evergreen.V198.Document
import Evergreen.V198.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V198.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V198.Document.Document
    , preferences : Preferences
    }
