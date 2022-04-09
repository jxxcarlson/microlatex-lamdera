module Evergreen.V304.User exposing (..)

import BoundedDeque
import Evergreen.V304.Document
import Evergreen.V304.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V304.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V304.Document.DocumentInfo
    , preferences : Preferences
    }
