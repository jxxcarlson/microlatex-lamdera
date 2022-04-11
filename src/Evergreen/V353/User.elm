module Evergreen.V353.User exposing (..)

import BoundedDeque
import Evergreen.V353.Document
import Evergreen.V353.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V353.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V353.Document.DocumentInfo
    , preferences : Preferences
    }
