module Evergreen.V376.User exposing (..)

import BoundedDeque
import Evergreen.V376.Document
import Evergreen.V376.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V376.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V376.Document.DocumentInfo
    , preferences : Preferences
    }
