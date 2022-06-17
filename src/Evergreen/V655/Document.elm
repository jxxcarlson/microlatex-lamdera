module Evergreen.V655.Document exposing (..)

import Effect.Time
import Evergreen.V655.Parser.Language


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
    , created : Effect.Time.Posix
    , modified : Effect.Time.Posix
    , content : String
    , title : String
    , public : Bool
    , author : Maybe String
    , language : Evergreen.V655.Parser.Language.Language
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
    , modified : Effect.Time.Posix
    , public : Bool
    }
