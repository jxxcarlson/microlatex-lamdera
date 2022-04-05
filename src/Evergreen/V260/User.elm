module Evergreen.V260.User exposing (..)

import BoundedDeque
import Evergreen.V260.Document
import Evergreen.V260.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V260.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V260.Document.DocumentInfo
    , preferences : Preferences
    }
