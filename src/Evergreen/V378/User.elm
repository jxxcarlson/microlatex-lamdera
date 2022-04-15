module Evergreen.V378.User exposing (..)

import BoundedDeque
import Evergreen.V378.Document
import Evergreen.V378.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V378.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V378.Document.DocumentInfo
    , preferences : Preferences
    }
