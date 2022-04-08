module Evergreen.V288.User exposing (..)

import BoundedDeque
import Evergreen.V288.Document
import Evergreen.V288.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V288.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V288.Document.DocumentInfo
    , preferences : Preferences
    }
