module Evergreen.V225.Document exposing (..)

import Evergreen.V225.Parser.Language
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
    , language : Evergreen.V225.Parser.Language.Language
    , readOnly : Bool
    , tags : List String
    }
