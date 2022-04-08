module Evergreen.V295.User exposing (..)

import BoundedDeque
import Evergreen.V295.Document
import Evergreen.V295.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V295.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V295.Document.DocumentInfo
    , preferences : Preferences
    }
