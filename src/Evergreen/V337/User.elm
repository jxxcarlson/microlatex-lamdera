module Evergreen.V337.User exposing (..)

import BoundedDeque
import Evergreen.V337.Document
import Evergreen.V337.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V337.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V337.Document.DocumentInfo
    , preferences : Preferences
    }
