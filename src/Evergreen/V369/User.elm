module Evergreen.V369.User exposing (..)

import BoundedDeque
import Evergreen.V369.Document
import Evergreen.V369.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V369.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V369.Document.DocumentInfo
    , preferences : Preferences
    }
