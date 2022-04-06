module Evergreen.V268.User exposing (..)

import BoundedDeque
import Evergreen.V268.Document
import Evergreen.V268.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V268.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V268.Document.DocumentInfo
    , preferences : Preferences
    }
