module Document exposing
    ( Access(..)
    , Document
    , DocumentInfo
    , currentAuthor
    , defaultSettings
    , empty
    , toDocInfo
    , wordCount
    )

import Parser.Language exposing (Language(..))
import Render.Settings
import Time


type alias Document =
    { id : String
    , publicId : String
    , created : Time.Posix
    , modified : Time.Posix
    , content : String
    , title : String
    , public : Bool
    , author : Maybe String
    , language : Language
    , readOnly : Bool
    , tags : List String
    }


toDocInfo : Document -> DocumentInfo
toDocInfo doc =
    { title = doc.title, id = doc.id, modified = doc.modified, public = doc.public }


type alias DocumentInfo =
    { title : String, id : String, modified : Time.Posix, public : Bool }


currentAuthor : Maybe Document -> String
currentAuthor mDoc =
    Maybe.andThen .author mDoc |> Maybe.withDefault ""


type alias Username =
    String


type Access
    = Shared { canRead : List Username, canWrite : List Username }


defaultSettings : Render.Settings.Settings
defaultSettings =
    { width = 500
    , titleSize = 30
    , paragraphSpacing = 28
    , showTOC = True
    , showErrorMessages = False
    , selectedId = ""
    }


empty =
    { id = "-3"
    , publicId = "-1"
    , created = Time.millisToPosix 0
    , modified = Time.millisToPosix 0
    , content = ""
    , title = "(Untitled)"
    , public = False
    , author = Nothing
    , language = MicroLaTeXLang
    , readOnly = False
    , tags = []
    }


wordCount : Document -> Int
wordCount doc =
    doc.content |> String.words |> List.length
