module Evergreen.Migrate.V205 exposing (..)

import BoundedDeque
import Dict
import Evergreen.V198.Authentication
import Evergreen.V198.Credentials
import Evergreen.V198.Document
import Evergreen.V198.Parser.Language
import Evergreen.V198.Types as Old
import Evergreen.V198.User
import Evergreen.V205.Authentication
import Evergreen.V205.Credentials
import Evergreen.V205.Document
import Evergreen.V205.Parser.Language
import Evergreen.V205.Types as New
import Evergreen.V205.User
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


injectLang : Evergreen.V198.Parser.Language.Language -> Evergreen.V205.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V198.Parser.Language.L0Lang ->
            Evergreen.V205.Parser.Language.L0Lang

        Evergreen.V198.Parser.Language.MicroLaTeXLang ->
            Evergreen.V205.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V205.Parser.Language.L0Lang


injectDocument : Evergreen.V198.Document.Document -> Evergreen.V205.Document.Document
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


identityCredentials : Evergreen.V198.Credentials.Credentials -> Evergreen.V205.Credentials.Credentials
identityCredentials (Evergreen.V198.Credentials.V1 a b) =
    Evergreen.V205.Credentials.V1 a b


identityUserData : Evergreen.V198.Authentication.UserData -> Evergreen.V205.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V198.User.User -> Evergreen.V205.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V205.Parser.Language.L0Lang }
    }


identityAuthenticationDict : Evergreen.V198.Authentication.AuthenticationDict -> Evergreen.V205.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
