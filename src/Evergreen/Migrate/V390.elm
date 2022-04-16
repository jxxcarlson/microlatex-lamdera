module Evergreen.Migrate.V390 exposing (..)

-- 378 >> 389
-- 382 >> 390

import BoundedDeque
import Dict
import Evergreen.V389.Authentication
import Evergreen.V389.Credentials
import Evergreen.V389.Document
import Evergreen.V389.Parser.Language
import Evergreen.V389.Types as Old
import Evergreen.V389.User
import Evergreen.V390.Authentication
import Evergreen.V390.Credentials
import Evergreen.V390.Document
import Evergreen.V390.Parser.Language
import Evergreen.V390.Types as New
import Evergreen.V390.User
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
          , publicIdDict = old.publicIdDict
          , abstractDict = old.abstractDict
          , usersDocumentsDict = old.usersDocumentsDict
          , publicDocuments = List.map injectDocument old.publicDocuments
          , documents = List.map injectDocument old.documents
          , connectionDict = Dict.empty
          , sharedDocumentDict = Dict.empty
          , chatDict = Dict.empty
          , chatGroupDict = Dict.empty
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


injectLang : Evergreen.V389.Parser.Language.Language -> Evergreen.V390.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V389.Parser.Language.L0Lang ->
            Evergreen.V390.Parser.Language.L0Lang

        Evergreen.V389.Parser.Language.MicroLaTeXLang ->
            Evergreen.V390.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V390.Parser.Language.L0Lang


injectDocument : Evergreen.V389.Document.Document -> Evergreen.V390.Document.Document
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
    , currentEditor = Nothing
    , share = Evergreen.V390.Document.NotShared
    , handling = Evergreen.V390.Document.DHStandard
    }


identityCredentials : Evergreen.V389.Credentials.Credentials -> Evergreen.V390.Credentials.Credentials
identityCredentials (Evergreen.V389.Credentials.V1 a b) =
    Evergreen.V390.Credentials.V1 a b


identityUserData : Evergreen.V389.Authentication.UserData -> Evergreen.V390.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V389.User.User -> Evergreen.V390.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V390.Parser.Language.L0Lang, group = Nothing }
    , chatGroups = []
    , sharedDocuments = []
    , sharedDocumentAuthors = Set.empty
    }


identityAuthenticationDict : Evergreen.V389.Authentication.AuthenticationDict -> Evergreen.V390.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
