module Evergreen.V308.Document exposing (..)

import Evergreen.V308.Parser.Language
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
    = ShareWith
        { readers : List Username
        , editors : List Username
        }
    | NotShared


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
    , language : Evergreen.V308.Parser.Language.Language
    , share : Share
    , tags : List String
    }
