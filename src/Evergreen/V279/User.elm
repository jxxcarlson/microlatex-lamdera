module Evergreen.V279.User exposing (..)

import BoundedDeque
import Evergreen.V279.Document
import Evergreen.V279.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V279.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V279.Document.DocumentInfo
    , preferences : Preferences
    }
