module Evergreen.V277.User exposing (..)

import BoundedDeque
import Evergreen.V277.Document
import Evergreen.V277.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V277.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V277.Document.DocumentInfo
    , preferences : Preferences
    }
