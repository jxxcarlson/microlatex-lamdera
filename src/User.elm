module User exposing
    ( Preferences
    , User
    , currentUserId
    , currentUsername
    , mRemoveEditor
    , removeEditor
    )

import BoundedDeque exposing (BoundedDeque)
import Chat.Message
import Document exposing (Document)
import Effect.Time
import Parser.Language exposing (Language)
import Set exposing (Set)


type alias User =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Effect.Time.Posix
    , modified : Effect.Time.Posix
    , docs : BoundedDeque Document.DocumentInfo
    , preferences : Preferences
    , chatGroups : List String -- names of chat groups
    , sharedDocuments : List { title : String, id : String, owner : String }
    , sharedDocumentAuthors : Set String -- names of people to whom a document is shared that I have access to (by ownership or share)
    , pings : List Chat.Message.ChatMessage
    }


currentUsername : Maybe User -> String
currentUsername currentUser =
    Maybe.map .username currentUser |> Maybe.withDefault "(nobody)"


currentUserId : Maybe User -> String
currentUserId currentUser =
    Maybe.map .id currentUser |> Maybe.withDefault "----"


mRemoveEditor : Maybe User -> Maybe Document -> Maybe Document
mRemoveEditor mUser mDoc =
    case ( mUser, mDoc ) of
        ( Just user, Just doc ) ->
            Just
                { doc | currentEditorList = List.filter (\item -> item.userId /= user.id) doc.currentEditorList }

        _ ->
            mDoc


removeEditor : User -> Document -> Document
removeEditor user doc =
    { doc | status = Document.DSReadOnly, currentEditorList = List.filter (\item -> item.userId /= user.id) doc.currentEditorList }


type alias Preferences =
    { language : Language, group : Maybe String }
