module Evergreen.V226.User exposing (..)

import BoundedDeque
import Evergreen.V226.Document
import Evergreen.V226.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V226.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V226.Document.DocumentInfo
    , preferences : Preferences
    }
