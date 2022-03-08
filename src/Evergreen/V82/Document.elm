module Evergreen.V82.Document exposing (..)

import Evergreen.V82.Parser.Language
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
    , language : Evergreen.V82.Parser.Language.Language
    , readOnly : Bool
    }
