module Evergreen.V555.Document exposing (..)

import Evergreen.V555.Parser.Language
import Time


type alias Username =
    String


type alias SharedWith =
    { readers : List Username
    , editors : List Username
    }


type alias EditorData =
    { userId : String
    , username : String
    }


type alias DocumentId =
    String


type DocumentHandling
    = DHStandard
    | Backup DocumentId
    | Version DocumentId Int


type DocStatus
    = DSCanEdit
    | DSReadOnly
    | DSSoftDelete


type alias Document =
    { id : String
    , publicId : String
    , created : Time.Posix
    , modified : Time.Posix
    , content : String
    , title : String
    , public : Bool
    , author : Maybe String
    , language : Evergreen.V555.Parser.Language.Language
    , currentEditorList : List EditorData
    , sharedWith : SharedWith
    , isShared : Bool
    , handling : DocumentHandling
    , tags : List String
    , status : DocStatus
    }


type alias DocumentInfo =
    { title : String
    , id : String
    , slug : Maybe String
    , modified : Time.Posix
    , public : Bool
    }
