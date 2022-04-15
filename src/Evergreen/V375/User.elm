module Evergreen.V375.User exposing (..)

import BoundedDeque
import Evergreen.V375.Document
import Evergreen.V375.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V375.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V375.Document.DocumentInfo
    , preferences : Preferences
    }
