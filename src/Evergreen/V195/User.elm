module Evergreen.V195.User exposing (..)

import Evergreen.V195.Parser.Language
import Time


type alias DocInfo =
    { title : String
    , id : String
    }


type alias Preferences =
    { language : Evergreen.V195.Parser.Language.Language
    }


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : List DocInfo
    , preferences : Preferences
    }
