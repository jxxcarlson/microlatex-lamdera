module Evergreen.V205.Document exposing (..)

import Evergreen.V205.Parser.Language
import Time


type alias DocumentInfo =
    { title : String
    , id : String
    , modified : Time.Posix
    , public : Bool
    }


type alias Document =
    { id : String
    , publicId : String
    , created : Time.Posix
    , modified : Time.Posix
    , content : String
    , title : String
    , public : Bool
    , author : Maybe String
    , language : Evergreen.V205.Parser.Language.Language
    , readOnly : Bool
    , tags : List String
    }
