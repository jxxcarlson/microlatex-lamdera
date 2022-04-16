module Evergreen.V391.Document exposing (..)

import Evergreen.V391.Parser.Language
import Time


type alias Username =
    String


type Share
    = ShareWith
        { readers : List Username
        , editors : List Username
        }
    | NotShared


type alias DocumentId =
    String


type DocumentHandling
    = DHStandard
    | Backup DocumentId
    | Version DocumentId Int


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
    , language : Evergreen.V391.Parser.Language.Language
    , share : Share
    , handling : DocumentHandling
    , tags : List String
    }


type alias DocumentInfo =
    { title : String
    , id : String
    , modified : Time.Posix
    , public : Bool
    }
