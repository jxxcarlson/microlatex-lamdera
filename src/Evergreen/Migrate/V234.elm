module Evergreen.Migrate.V234 exposing (..)

--- V234

import BoundedDeque
import Dict
import Evergreen.V226.Authentication
import Evergreen.V226.Credentials
import Evergreen.V226.Document
import Evergreen.V226.Parser.Language
import Evergreen.V226.Types as Old
import Evergreen.V226.User
import Evergreen.V234.Authentication
import Evergreen.V234.Credentials
import Evergreen.V234.Document
import Evergreen.V234.Parser.Language
import Evergreen.V234.Types as New
import Evergreen.V234.User
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


injectLang : Evergreen.V226.Parser.Language.Language -> Evergreen.V234.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V226.Parser.Language.L0Lang ->
            Evergreen.V234.Parser.Language.L0Lang

        Evergreen.V226.Parser.Language.MicroLaTeXLang ->
            Evergreen.V234.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V234.Parser.Language.L0Lang


injectDocument : Evergreen.V226.Document.Document -> Evergreen.V234.Document.Document
injectDocument oldDocument =
    { id = oldDocument.id
    , publicId = oldDocument.publicId
    , created = oldDocument.created
    , modified = oldDocument.modified
    , content = oldDocument.content
    , title = oldDocument.title
    , public = oldDocument.public
    , author = oldDocument.author
    , currentEditor = Nothing
    , language = injectLang oldDocument.language
    , share = Evergreen.V234.Document.Private
    , tags = []
    }


identityCredentials : Evergreen.V226.Credentials.Credentials -> Evergreen.V234.Credentials.Credentials
identityCredentials (Evergreen.V226.Credentials.V1 a b) =
    Evergreen.V234.Credentials.V1 a b


identityUserData : Evergreen.V226.Authentication.UserData -> Evergreen.V234.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V226.User.User -> Evergreen.V234.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V234.Parser.Language.L0Lang }
    }


identityAuthenticationDict : Evergreen.V226.Authentication.AuthenticationDict -> Evergreen.V234.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
