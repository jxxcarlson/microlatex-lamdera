module Evergreen.V374.User exposing (..)

import BoundedDeque
import Evergreen.V374.Document
import Evergreen.V374.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V374.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V374.Document.DocumentInfo
    , preferences : Preferences
    }
