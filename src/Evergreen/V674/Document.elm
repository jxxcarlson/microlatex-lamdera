module Evergreen.V674.Document exposing (..)

import Effect.Lamdera
import Effect.Time
import Evergreen.V674.Parser.Language


type alias Username =
    String


type alias SharedWith =
    { readers : List Username
    , editors : List Username
    }


type alias EditorData =
    { userId : String
    , username : String
    , clients : List Effect.Lamdera.ClientId
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
    , language : Evergreen.V674.Parser.Language.Language
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
