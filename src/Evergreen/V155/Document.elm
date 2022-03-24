module Evergreen.V155.Document exposing (..)

import Evergreen.V155.Parser.Language
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
    , language : Evergreen.V155.Parser.Language.Language
    , readOnly : Bool
    }
