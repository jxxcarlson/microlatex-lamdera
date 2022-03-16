module Evergreen.V119.Document exposing (..)

import Evergreen.V119.Parser.Language
import Time


type alias Document =
    { id : String
    , publicId : String
    , created : Time.Posix
    , modified : Time.Posix
    , content : String
    , title : String
    , public : Bool
    , author : Maybe String
    , language : Evergreen.V119.Parser.Language.Language
    , readOnly : Bool
    }
