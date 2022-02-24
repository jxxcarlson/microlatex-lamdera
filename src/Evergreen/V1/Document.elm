module Evergreen.V1.Document exposing (..)

import Evergreen.V1.Parser.Language
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
    , language : Evergreen.V1.Parser.Language.Language
    , readOnly : Bool
    }
