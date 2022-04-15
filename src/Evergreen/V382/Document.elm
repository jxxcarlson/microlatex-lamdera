module Evergreen.V382.Document exposing (..)

import Evergreen.V382.Parser.Language
import Time


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
    , language : Evergreen.V382.Parser.Language.Language
    , share : Share
    , tags : List String
    }


type alias DocumentId =
    String


type alias DocumentInfo =
    { title : String
    , id : String
    , modified : Time.Posix
    , public : Bool
    }
