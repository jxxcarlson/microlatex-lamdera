module Evergreen.V234.User exposing (..)

import BoundedDeque
import Evergreen.V234.Document
import Evergreen.V234.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V234.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V234.Document.DocumentInfo
    , preferences : Preferences
    }
