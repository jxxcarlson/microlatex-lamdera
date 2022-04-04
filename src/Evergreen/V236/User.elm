module Evergreen.V236.User exposing (..)

import BoundedDeque
import Evergreen.V236.Document
import Evergreen.V236.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V236.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V236.Document.DocumentInfo
    , preferences : Preferences
    }
