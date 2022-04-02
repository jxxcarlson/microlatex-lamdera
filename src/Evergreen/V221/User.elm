module Evergreen.V221.User exposing (..)

import BoundedDeque
import Evergreen.V221.Document
import Evergreen.V221.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V221.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V221.Document.DocumentInfo
    , preferences : Preferences
    }
