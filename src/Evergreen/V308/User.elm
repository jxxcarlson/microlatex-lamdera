module Evergreen.V308.User exposing (..)

import BoundedDeque
import Evergreen.V308.Document
import Evergreen.V308.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V308.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V308.Document.DocumentInfo
    , preferences : Preferences
    }
