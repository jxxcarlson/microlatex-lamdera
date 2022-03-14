module Evergreen.V99.Document exposing (..)

import Evergreen.V99.Parser.Language
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
    , language : Evergreen.V99.Parser.Language.Language
    , readOnly : Bool
    }
