module Evergreen.V259.User exposing (..)

import BoundedDeque
import Evergreen.V259.Document
import Evergreen.V259.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V259.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V259.Document.DocumentInfo
    , preferences : Preferences
    }
