module User exposing (Preferences, User)

import BoundedDeque exposing (BoundedDeque)
import Document exposing (Document)
import Parser.Language exposing (Language(..))
import Time


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque Document.DocumentInfo
    , preferences : Preferences
    }


type alias Preferences =
    { language : Language }
