module Evergreen.V348.User exposing (..)

import BoundedDeque
import Evergreen.V348.Document
import Evergreen.V348.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V348.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V348.Document.DocumentInfo
    , preferences : Preferences
    }
