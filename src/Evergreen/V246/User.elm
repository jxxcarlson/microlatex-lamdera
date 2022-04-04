module Evergreen.V246.User exposing (..)

import BoundedDeque
import Evergreen.V246.Document
import Evergreen.V246.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V246.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V246.Document.DocumentInfo
    , preferences : Preferences
    }
