module Evergreen.Migrate.V194 exposing (..)

import Dict
import Evergreen.V193.Authentication
import Evergreen.V193.Credentials
import Evergreen.V193.Document
import Evergreen.V193.Parser.Language
import Evergreen.V193.Types as Old
import Evergreen.V193.User
import Evergreen.V194.Authentication
import Evergreen.V194.Credentials
import Evergreen.V194.Document
import Evergreen.V194.Parser.Language
import Evergreen.V194.Types as New
import Evergreen.V194.User
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
          , publicIdDict = old.publicIdDict
          , abstractDict = old.abstractDict
          , usersDocumentsDict = old.usersDocumentsDict
          , publicDocuments = List.map injectDocument old.publicDocuments
          , documents = List.map injectDocument old.documents
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


injectLang : Evergreen.V193.Parser.Language.Language -> Evergreen.V194.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V193.Parser.Language.L0Lang ->
            Evergreen.V194.Parser.Language.L0Lang

        Evergreen.V193.Parser.Language.MicroLaTeXLang ->
            Evergreen.V194.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V194.Parser.Language.L0Lang


injectDocument : Evergreen.V193.Document.Document -> Evergreen.V194.Document.Document
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
    , readOnly = oldDocument.readOnly
    , tags = []
    }


identityCredentials : Evergreen.V193.Credentials.Credentials -> Evergreen.V194.Credentials.Credentials
identityCredentials (Evergreen.V193.Credentials.V1 a b) =
    Evergreen.V194.Credentials.V1 a b


identityUserData : Evergreen.V193.Authentication.UserData -> Evergreen.V194.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V193.User.User -> Evergreen.V194.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = []
    , preferences = { language = Evergreen.V194.Parser.Language.L0Lang }
    }


identityAuthenticationDict : Evergreen.V193.Authentication.AuthenticationDict -> Evergreen.V194.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
