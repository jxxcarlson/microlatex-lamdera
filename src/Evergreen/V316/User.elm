module Evergreen.V316.User exposing (..)

import BoundedDeque
import Evergreen.V316.Document
import Evergreen.V316.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V316.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V316.Document.DocumentInfo
    , preferences : Preferences
    }
