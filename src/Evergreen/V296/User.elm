module Evergreen.V296.User exposing (..)

import BoundedDeque
import Evergreen.V296.Document
import Evergreen.V296.Parser.Language
import Time


type alias Preferences =
    { language : Evergreen.V296.Parser.Language.Language
    , group : Maybe String
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque.BoundedDeque Evergreen.V296.Document.DocumentInfo
    , preferences : Preferences
    }
