module Evergreen.V289.User exposing (..)

import BoundedDeque
import Evergreen.V289.Document
import Evergreen.V289.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V289.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V289.Document.DocumentInfo
    , preferences : Preferences
    }
