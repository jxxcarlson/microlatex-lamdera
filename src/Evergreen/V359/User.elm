module Evergreen.V359.User exposing (..)

import BoundedDeque
import Evergreen.V359.Document
import Evergreen.V359.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V359.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V359.Document.DocumentInfo
    , preferences : Preferences
    }
