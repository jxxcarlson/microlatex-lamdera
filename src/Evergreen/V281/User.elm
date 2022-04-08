module Evergreen.V281.User exposing (..)

import BoundedDeque
import Evergreen.V281.Document
import Evergreen.V281.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V281.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V281.Document.DocumentInfo
    , preferences : Preferences
    }
