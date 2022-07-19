module Document exposing
    ( DocStatus(..)
    , Document
    , DocumentHandling(..)
    , DocumentId
    , DocumentInfo
    , EditorData
    , SharedWith
    , SourceTextRecord
    , addTag
    , canEditSharedDoc
    , currentAuthor
    , defaultSettings
    , documentFromListViaId
    , empty
    , getSlug
    , location
    , makeBackup
    , numberOfEditors
    , removeTag
    , setTags
    , shareToString
    , testDoc
    , toDocInfo
    , wordCount
    )

import Effect.Lamdera exposing (ClientId)
import Effect.Time
import Element
import List.Extra
import Parser.Helpers
import Parser.Language exposing (Language(..))
import Render.Settings
import TextTools


type alias Document =
    { id : String
    , publicId : String
    , created : Effect.Time.Posix
    , modified : Effect.Time.Posix
    , content : String
    , title : String
    , public : Bool -- document visible to others if public == True
    , author : Maybe String
    , language : Language
    , currentEditorList : List EditorData -- the username of the person currently editing the document
    , sharedWith : SharedWith
    , isShared : Bool
    , handling : DocumentHandling
    , tags : List String
    , status : DocStatus
    }


type alias EditorData =
    { userId : String, username : String, clients : List ClientId }


type DocStatus
    = DSCanEdit
    | DSReadOnly
    | DSSoftDelete


type alias Location =
    { x : Int, y : Int }


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
            List.Extra.last lines |> Maybe.withDefault "1" |> String.length

        row =
            List.length lines
    in
    { x = column, y = row - 1 }


type alias SourceTextRecord =
    { position : Int, source : String }


getSlug : Document -> Maybe String
getSlug doc =
    let
        username =
            doc.author |> Maybe.withDefault "-"
    in
    List.filter (\item -> String.contains (username ++ ":") item) doc.tags
        |> List.head


{-|

    This type determines who can read and who can edit a document.
    Private documents can only be edited by their author.
    The 'public' field of a document determines whether
    it is visible to all users; it has nothing to do with the
    value of the share field.

-}
type alias SharedWith =
    { readers : List Username, editors : List Username }


type DocumentHandling
    = DHStandard
    | Backup DocumentId
    | Version DocumentId Int


type alias DocumentId =
    String


numberOfEditors : Maybe Document -> Int
numberOfEditors document =
    document |> Maybe.map (.currentEditorList >> List.length) |> Maybe.withDefault 0


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


shareToString : SharedWith -> String
shareToString { readers, editors } =
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
        List.member username doc.sharedWith.editors


toDocInfo : Document -> DocumentInfo
toDocInfo doc =
    let
        author =
            doc.author |> Maybe.withDefault "--"

        slug =
            List.filter (\item -> String.contains author item) doc.tags |> List.head
    in
    { title = doc.title, id = doc.id, slug = slug, modified = doc.modified, public = doc.public }


type alias DocumentInfo =
    { title : String, id : String, slug : Maybe String, modified : Effect.Time.Posix, public : Bool }


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
    , selectedSlug = Nothing
    , backgroundColor = Element.rgb 1 1 1
    , titlePrefix = ""
    }


empty =
    { id = "-3"
    , publicId = "-1"
    , created = Effect.Time.millisToPosix 0
    , modified = Effect.Time.millisToPosix 0
    , content = ""
    , title = "(Untitled)"
    , public = False
    , author = Nothing
    , currentEditorList = []
    , language = MicroLaTeXLang
    , sharedWith = { readers = [], editors = [] }
    , isShared = False
    , tags = []
    , handling = DHStandard
    , status = DSCanEdit
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
    , currentEditorList = []
    , language = doc.language
    , sharedWith = doc.sharedWith
    , isShared = False
    , handling = Backup doc.id
    , tags = doc.tags
    , status = doc.status
    }


testDoc =
    { empty | content = "| title\nHo ho ho\n\n[tags one, two, three]\n\n", language = L0Lang }


wordCount : Document -> Int
wordCount doc =
    doc.content |> String.words |> List.length


addTag : String -> Document -> Document
addTag tag doc =
    let
        oldTagString_ =
            TextTools.getRawItem doc.language "tags" doc.content

        newTags =
            tag :: doc.tags |> String.join ", "

        newTagString =
            case doc.language of
                L0Lang ->
                    [ "[tags ", newTags, "]" ] |> String.join ""

                MicroLaTeXLang ->
                    [ "\\tags{", newTags, "}" ] |> String.join ""

                XMarkdownLang ->
                    [ "@[tags ", newTags, "]" ] |> String.join ""

                _ ->
                    ""

        newContent =
            case oldTagString_ of
                Nothing ->
                    let
                        tagString =
                            case doc.language of
                                L0Lang ->
                                    "[tags folder:deleted]"

                                MicroLaTeXLang ->
                                    "\\tags{folder:deleted}"

                                XMarkdownLang ->
                                    "@[tags folder:deleted]"

                                PlainTextLang ->
                                    ""
                    in
                    case String.split "\n\n" doc.content of
                        head :: rest ->
                            head :: tagString :: rest |> String.join "\n\n"

                        [] ->
                            ""

                Just oldTagString ->
                    String.replace oldTagString newTagString doc.content
    in
    { doc | content = newContent }


removeTag : String -> Document -> Document
removeTag tag doc =
    let
        oldTagsString_ =
            TextTools.getRawItem doc.language "tags" doc.content

        newTags =
            doc.tags |> List.filter (\tag_ -> tag_ /= tag)

        newTagString =
            case doc.language of
                L0Lang ->
                    [ "[tags ", String.join ", " newTags, "]" ] |> String.join ""

                MicroLaTeXLang ->
                    [ "\\tags{", String.join ", " newTags, "}" ] |> String.join ""

                XMarkdownLang ->
                    [ "@[tags ", String.join ", " newTags, "]" ] |> String.join ""

                PlainTextLang ->
                    ""

        newContent =
            case oldTagsString_ of
                Nothing ->
                    doc.content

                Just oldTagString ->
                    String.replace oldTagString newTagString doc.content
    in
    { doc | content = newContent, tags = newTags }
