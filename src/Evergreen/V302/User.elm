module Evergreen.V302.User exposing (..)

import BoundedDeque
import Evergreen.V302.Document
import Evergreen.V302.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V302.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V302.Document.DocumentInfo
    , preferences : Preferences
    }
