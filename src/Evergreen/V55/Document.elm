module Evergreen.V55.Document exposing (..)

import Evergreen.V55.Parser.Language
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
    , language : Evergreen.V55.Parser.Language.Language
    , readOnly : Bool
    }
