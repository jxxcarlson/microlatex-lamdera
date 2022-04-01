module User exposing (DocInfo, Preferences, User)

import Parser.Language exposing (Language(..))
import Time


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


type alias DocInfo =
    { title : String, id : String }


type alias Preferences =
    { language : Language }
