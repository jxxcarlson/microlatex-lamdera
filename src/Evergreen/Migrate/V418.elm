module Evergreen.Migrate.V418 exposing (..)

-- 389 >> 416
-- 390 >> 418

import BoundedDeque
import Dict
import Evergreen.V416.Authentication
import Evergreen.V416.Credentials
import Evergreen.V416.Document
import Evergreen.V416.Parser.Language
import Evergreen.V416.Types as Old
import Evergreen.V416.User
import Evergreen.V418.Authentication
import Evergreen.V418.Credentials
import Evergreen.V418.Document
import Evergreen.V418.Parser.Language
import Evergreen.V418.Types as New
import Evergreen.V418.User
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


injectLang : Evergreen.V416.Parser.Language.Language -> Evergreen.V418.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V416.Parser.Language.L0Lang ->
            Evergreen.V418.Parser.Language.L0Lang

        Evergreen.V416.Parser.Language.MicroLaTeXLang ->
            Evergreen.V418.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V418.Parser.Language.L0Lang


injectDocument : Evergreen.V416.Document.Document -> Evergreen.V418.Document.Document
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
    , share = Evergreen.V418.Document.NotShared
    , handling = Evergreen.V418.Document.DHStandard
    , status = Evergreen.V418.Document.DSNormal
    }


identityCredentials : Evergreen.V416.Credentials.Credentials -> Evergreen.V418.Credentials.Credentials
identityCredentials (Evergreen.V416.Credentials.V1 a b) =
    Evergreen.V418.Credentials.V1 a b


identityUserData : Evergreen.V416.Authentication.UserData -> Evergreen.V418.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V416.User.User -> Evergreen.V418.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V418.Parser.Language.L0Lang, group = Nothing }
    , chatGroups = []
    , sharedDocuments = []
    , sharedDocumentAuthors = Set.empty
    }


identityAuthenticationDict : Evergreen.V416.Authentication.AuthenticationDict -> Evergreen.V418.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata)
        oldAuthenticationDict
