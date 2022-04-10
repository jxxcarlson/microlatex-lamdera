module Evergreen.V342.User exposing (..)

import BoundedDeque
import Evergreen.V342.Document
import Evergreen.V342.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V342.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V342.Document.DocumentInfo
    , preferences : Preferences
    }
