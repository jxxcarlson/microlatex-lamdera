module Evergreen.V258.User exposing (..)

import BoundedDeque
import Evergreen.V258.Document
import Evergreen.V258.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V258.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V258.Document.DocumentInfo
    , preferences : Preferences
    }
