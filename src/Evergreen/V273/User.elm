module Evergreen.V273.User exposing (..)

import BoundedDeque
import Evergreen.V273.Document
import Evergreen.V273.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V273.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V273.Document.DocumentInfo
    , preferences : Preferences
    }
