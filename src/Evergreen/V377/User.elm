module Evergreen.V377.User exposing (..)

import BoundedDeque
import Evergreen.V377.Document
import Evergreen.V377.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V377.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V377.Document.DocumentInfo
    , preferences : Preferences
    }
