module Document exposing
    ( Document
    , DocumentHandling(..)
    , DocumentId
    , DocumentInfo
    , Share(..)
    , SourceTextRecord
    , canEditSharedDoc
    , currentAuthor
    , defaultSettings
    , documentFromListViaId
    , empty
    , location
    , makeBackup
    , setTags
    , shareToString
    , testDoc
    , toDocInfo
    , wordCount
    )

import Element
import List.Extra
import Parser.Helpers
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
    , handling : DocumentHandling
    , tags : List String
    }


type alias SourceTextRecord =
    { position : Int, source : String }


type alias Location =
    { row : Int, column : Int }


{-| Get the location of the cursor where the
row and column positions are 1-based.
-}
location : Int -> String -> Location
location position source =
    let
        prefix =
            String.left position source

        lines =
            String.lines prefix

        column =
            List.Extra.last lines |> Maybe.withDefault "0" |> String.length

        row =
            List.length lines
    in
    { row = row, column = column }


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


type DocumentHandling
    = DHStandard
    | Backup DocumentId
    | Version DocumentId Int


type alias DocumentId =
    String


documentFromListViaId : DocumentId -> List Document -> Maybe Document
documentFromListViaId id docs =
    docs |> List.filter (\doc -> doc.id == id) |> List.head


{-| Find tags in the text of the document and set them in the tag field
-}
setTags : Document -> Document
setTags doc =
    let
        tagLines =
            case doc.language of
                L0Lang ->
                    String.lines doc.content
                        |> Parser.Helpers.getFirstOccurrence (\line -> String.contains "[tags " line)
                        |> Maybe.map (\s -> s |> String.replace "[tags " "" |> String.replace "]" "")

                MicroLaTeXLang ->
                    String.lines doc.content
                        |> Parser.Helpers.getFirstOccurrence (\line -> String.contains "\\tags{" line)
                        |> Maybe.map (\s -> s |> String.replace "\\tags{" "" |> String.replace "}" "")

                XMarkdownLang ->
                    String.lines doc.content
                        |> Parser.Helpers.getFirstOccurrence (\line -> String.contains "@[tags" line)
                        |> Maybe.map (\s -> s |> String.replace "@[tags" "" |> String.replace "]" "")

                PlainTextLang ->
                    String.lines doc.content
                        |> Parser.Helpers.getFirstOccurrence (\line -> String.contains "[tags " line)
                        |> Maybe.map (\s -> s |> String.replace "[tags " "" |> String.replace "]" "")

        tags =
            tagLines |> Maybe.withDefault "" |> String.split ", " |> List.map String.trim
    in
    { doc | tags = tags }


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
    , backgroundColor = Element.rgb 1 1 1
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
    , handling = DHStandard
    }


makeBackup : Document -> Document
makeBackup doc =
    { id = doc.id ++ "-backup"
    , publicId = doc.publicId
    , created = doc.created
    , modified = doc.modified
    , content = String.replace doc.title (doc.title ++ " (BAK)") doc.content
    , title = doc.title ++ " (BAK)"
    , public = doc.public
    , author = doc.author
    , currentEditor = Nothing
    , language = doc.language
    , share = NotShared
    , handling = Backup doc.id
    , tags = doc.tags
    }


testDoc =
    { empty | content = "| title\nHo ho ho\n\n[tags one, two, three]\n\n", language = L0Lang }


wordCount : Document -> Int
wordCount doc =
    doc.content |> String.words |> List.length
