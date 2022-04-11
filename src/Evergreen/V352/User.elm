module Evergreen.V352.User exposing (..)

import BoundedDeque
import Evergreen.V352.Document
import Evergreen.V352.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V352.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V352.Document.DocumentInfo
    , preferences : Preferences
    }
