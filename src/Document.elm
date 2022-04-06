module Document exposing
    ( Document
    , DocumentInfo
    , Share(..)
    , canEditSharedDoc
    , currentAuthor
    , defaultSettings
    , empty
    , shareToString
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
    , public : Bool -- document visible to others if public == True
    , author : Maybe String
    , currentEditor : Maybe String -- the username of the person currently editing the document
    , language : Language
    , share : Share
    , tags : List String
    }


{-|

    This type determines who can read and who can edit a document.
    Private documents can only be edited by their author.
    The 'public' field of a document determines whether
    it is visible to all users; it has nothing to do with the
    value of the share field.

-}
type Share
    = ShareWith { readers : List Username, editors : List Username }
    | NotShared


shareToString : Share -> String
shareToString share =
    case share of
        NotShared ->
            "not shared"

        ShareWith { readers, editors } ->
            let
                editors1 =
                    editors |> String.join ", "

                editors2 =
                    if editors1 == "" then
                        ""

                    else
                        "editors: " ++ editors1

                readers1 =
                    readers |> String.join ", "

                readers2 =
                    if readers1 == "" then
                        ""

                    else
                        "readers: " ++ readers1
            in
            [ editors2, readers2 ] |> String.join "; "


canEditSharedDoc username doc =
    if doc.author == Just username then
        True

    else
        case doc.share of
            NotShared ->
                False

            ShareWith { editors } ->
                List.member username editors


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
    , currentEditor = Nothing
    , language = MicroLaTeXLang
    , share = NotShared
    , tags = []
    }


wordCount : Document -> Int
wordCount doc =
    doc.content |> String.words |> List.length
