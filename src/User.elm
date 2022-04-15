module User exposing (Preferences, User)

import BoundedDeque exposing (BoundedDeque)
import Document
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
    }


type alias Preferences =
    { language : Language, group : Maybe String }


type alias GroupMembers =
    { -- user names for documents shared to the given user
      sharedDocuments : List String

    -- user names for members of chat groups to which the given user is a member
    , chatGroups : List String
    }
