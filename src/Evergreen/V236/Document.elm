module Evergreen.V236.Document exposing (..)

import Evergreen.V236.Parser.Language
import Time


type alias DocumentInfo =
    { title : String
    , id : String
    , modified : Time.Posix
    , public : Bool
    }


type alias Username =
    String


type Share
    = Share
        { readers : List Username
        , editors : List Username
        }
    | Private


type alias Document =
    { id : String
    , publicId : String
    , created : Time.Posix
    , modified : Time.Posix
    , content : String
    , title : String
    , public : Bool
    , author : Maybe String
    , currentEditor : Maybe String
    , language : Evergreen.V236.Parser.Language.Language
    , share : Share
    , tags : List String
    }
