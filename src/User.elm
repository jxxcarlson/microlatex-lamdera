module User exposing
    ( Preferences
    , User
    , addEditor
    , mRemoveEditor
    , removeEditor
    )

import BoundedDeque exposing (BoundedDeque)
import Chat.Message
import Document exposing (Document)
import List.Extra
import Parser.Language exposing (Language)
import Set exposing (Set)
import Time


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
    , docs : BoundedDeque Document.DocumentInfo
    , preferences : Preferences
    , chatGroups : List String -- names of chat groups
    , sharedDocuments : List { title : String, id : String, owner : String }
    , sharedDocumentAuthors : Set String -- names of people to whom a document is shared that I have access to (by ownership or share)
    , pings : List Chat.Message.ChatMessage
    }


applyIfDefined f mA b =
    case mA of
        Nothing ->
            b

        Just a_ ->
            f a_ b


addEditor : Maybe User -> Document -> Document
addEditor mUser doc =
    let
        f user doc_ =
            { doc_ | status = Document.DSNormal, currentEditorList = insertInList { userId = user.id, username = user.username } doc_.currentEditorList }
    in
    applyIfDefined f mUser doc


insertInList : a -> List a -> List a
insertInList a list =
    if List.Extra.notMember a list then
        a :: list

    else
        list


mRemoveEditor : Maybe User -> Maybe Document -> Maybe Document
mRemoveEditor mUser mDoc =
    case ( mUser, mDoc ) of
        ( Nothing, _ ) ->
            mDoc

        ( _, Nothing ) ->
            mDoc

        ( Just user, Just doc ) ->
            Just { doc | status = Document.DSReadOnly, currentEditorList = List.filter (\item -> item.userId /= user.id) doc.currentEditorList }


removeEditor : User -> Document -> Document
removeEditor user doc =
    { doc | status = Document.DSReadOnly, currentEditorList = List.filter (\item -> item.userId /= user.id) doc.currentEditorList }


type alias Preferences =
    { language : Language, group : Maybe String }


type alias GroupMembers =
    { -- user names for documents shared to the given user
      sharedDocuments : List String

    -- user names for members of chat groups to which the given user is a member
    , chatGroups : List String
    }
