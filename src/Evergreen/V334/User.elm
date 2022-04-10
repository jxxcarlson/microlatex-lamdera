module Evergreen.V334.User exposing (..)

import BoundedDeque
import Evergreen.V334.Document
import Evergreen.V334.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V334.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V334.Document.DocumentInfo
    , preferences : Preferences
    }
