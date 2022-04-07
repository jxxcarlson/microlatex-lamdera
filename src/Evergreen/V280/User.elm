module Evergreen.V280.User exposing (..)

import BoundedDeque
import Evergreen.V280.Document
import Evergreen.V280.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V280.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V280.Document.DocumentInfo
    , preferences : Preferences
    }
