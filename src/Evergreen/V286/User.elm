module Evergreen.V286.User exposing (..)

import BoundedDeque
import Evergreen.V286.Document
import Evergreen.V286.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V286.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V286.Document.DocumentInfo
    , preferences : Preferences
    }
