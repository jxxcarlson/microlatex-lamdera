module Evergreen.Migrate.V546 exposing (..)

import BoundedDeque
import Deque
import Dict
import Evergreen.V537.Authentication
import Evergreen.V537.Credentials
import Evergreen.V537.Document
import Evergreen.V537.Parser.Language
import Evergreen.V537.Types as Old
import Evergreen.V537.User
import Evergreen.V546.Authentication
import Evergreen.V546.Credentials
import Evergreen.V546.Document
import Evergreen.V546.Parser.Language
import Evergreen.V546.Types as New
import Evergreen.V546.User
import Lamdera.Migrations exposing (..)


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
          , sharedDocumentDict = Dict.map (\_ sharedDoc -> migrateSharedDocument sharedDoc) old.sharedDocumentDict
          , chatDict = old.chatDict
          , chatGroupDict = old.chatGroupDict
          , editEvents = Deque.empty
          }
        , Cmd.none
        )


migrateSharedDocument : Old.SharedDocument -> New.SharedDocument
migrateSharedDocument sharedDoc =
    { title = sharedDoc.title
    , id = sharedDoc.id
    , author = sharedDoc.author
    , share = sharedDoc.share
    , currentEditors = []
    }


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


injectLang : Evergreen.V537.Parser.Language.Language -> Evergreen.V546.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V537.Parser.Language.L0Lang ->
            Evergreen.V546.Parser.Language.L0Lang

        Evergreen.V537.Parser.Language.MicroLaTeXLang ->
            Evergreen.V546.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V546.Parser.Language.L0Lang


injectDocument : Evergreen.V537.Document.Document -> Evergreen.V546.Document.Document
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
    , tags = oldDocument.tags
    , currentEditorList = []
    , isShared = False
    , sharedWith = oldDocument.sharedWith
    , handling = Evergreen.V546.Document.DHStandard
    , status = Evergreen.V546.Document.DSReadOnly
    }


identityCredentials : Evergreen.V537.Credentials.Credentials -> Evergreen.V546.Credentials.Credentials
identityCredentials (Evergreen.V537.Credentials.V1 a b) =
    Evergreen.V546.Credentials.V1 a b


identityUserData : Evergreen.V537.Authentication.UserData -> Evergreen.V546.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V537.User.User -> Evergreen.V546.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V546.Parser.Language.L0Lang, group = Nothing }
    , chatGroups = oldUser.chatGroups
    , sharedDocuments = oldUser.sharedDocuments
    , sharedDocumentAuthors = oldUser.sharedDocumentAuthors
    , pings = []
    }


identityAuthenticationDict : Evergreen.V537.Authentication.AuthenticationDict -> Evergreen.V546.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
