module Evergreen.V506.Document exposing (..)

import Evergreen.V506.Parser.Language
import Lamdera
import Time


type alias Username =
    String


type alias SharedWith =
    { readers : List Username
    , editors : List Username
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
    , language : Evergreen.V506.Parser.Language.Language
    , currentEditorList :
        List
            { userId : String
            , username : String
            , clientId : Lamdera.ClientId
            }
    , sharedWith : SharedWith
    , isShared : Bool
    , handling : DocumentHandling
    , tags : List String
    , status : DocStatus
    }


type alias DocumentInfo =
    { title : String
    , id : String
    , modified : Time.Posix
    , public : Bool
    }
