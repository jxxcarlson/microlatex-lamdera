module Evergreen.V351.User exposing (..)

import BoundedDeque
import Evergreen.V351.Document
import Evergreen.V351.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V351.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V351.Document.DocumentInfo
    , preferences : Preferences
    }
