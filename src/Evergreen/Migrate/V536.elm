module Evergreen.Migrate.V536 exposing (..)

-- 533 >> 536
-- 526 >> 533
--- xx ---

import BoundedDeque
import Deque
import Dict
import Evergreen.V533.Authentication
import Evergreen.V533.Credentials
import Evergreen.V533.Document
import Evergreen.V533.Parser.Language
import Evergreen.V533.Types as Old
import Evergreen.V533.User
import Evergreen.V536.Authentication
import Evergreen.V536.Credentials
import Evergreen.V536.Document
import Evergreen.V536.Parser.Language
import Evergreen.V536.Types as New
import Evergreen.V536.User
import Lamdera.Migrations exposing (..)
import Set


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    ModelMigrated
        ( { message = old.message
          , currentTime = old.currentTime
          , randomSeed = old.randomSeed
          , uuidCount = old.uuidCount
          , randomAtmosphericInt = old.randomAtmosphericInt
          , authenticationDict = identityAuthenticationDict old.authenticationDict
          , documentDict = Dict.map (\_ doc -> injectDocument doc) old.documentDict
          , authorIdDict = old.authorIdDict
          , slugDict = Dict.empty
          , publicIdDict = old.publicIdDict
          , abstractDict = old.abstractDict
          , usersDocumentsDict = old.usersDocumentsDict
          , publicDocuments = List.map injectDocument old.publicDocuments
          , documents = List.map injectDocument old.documents
          , connectionDict = old.connectionDict
          , sharedDocumentDict = old.sharedDocumentDict
          , chatDict = old.chatDict
          , chatGroupDict = old.chatGroupDict
          , editEvents = Deque.empty
          }
        , Cmd.none
        )


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    MsgUnchanged


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged



-- Type Maps


injectLang : Evergreen.V533.Parser.Language.Language -> Evergreen.V536.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V533.Parser.Language.L0Lang ->
            Evergreen.V536.Parser.Language.L0Lang

        Evergreen.V533.Parser.Language.MicroLaTeXLang ->
            Evergreen.V536.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V536.Parser.Language.L0Lang


injectDocument : Evergreen.V533.Document.Document -> Evergreen.V536.Document.Document
injectDocument oldDocument =
    { id = oldDocument.id
    , publicId = oldDocument.publicId
    , created = oldDocument.created
    , modified = oldDocument.modified
    , content = oldDocument.content
    , title = oldDocument.title
    , public = oldDocument.public
    , author = oldDocument.author
    , language = injectLang oldDocument.language
    , tags = []
    , currentEditorList = []

    -- , currentEditor = Nothing
    --, share = Evergreen.V536.Document.NotShared
    , isShared = False
    , sharedWith =
        { readers = []
        , editors = []
        }
    , handling = Evergreen.V536.Document.DHStandard
    , status = Evergreen.V536.Document.DSReadOnly
    }


identityCredentials : Evergreen.V533.Credentials.Credentials -> Evergreen.V536.Credentials.Credentials
identityCredentials (Evergreen.V533.Credentials.V1 a b) =
    Evergreen.V536.Credentials.V1 a b


identityUserData : Evergreen.V533.Authentication.UserData -> Evergreen.V536.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V533.User.User -> Evergreen.V536.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V536.Parser.Language.L0Lang, group = Nothing }
    , chatGroups = oldUser.chatGroups
    , sharedDocuments = oldUser.sharedDocuments
    , sharedDocumentAuthors = oldUser.sharedDocumentAuthors
    , pings = []
    }


identityAuthenticationDict : Evergreen.V533.Authentication.AuthenticationDict -> Evergreen.V536.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
