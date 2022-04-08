module Evergreen.Migrate.V281 exposing (..)

-- V281 >> V281
-- V280 >> V280

import BoundedDeque
import Dict
import Evergreen.V280.Authentication
import Evergreen.V280.Credentials
import Evergreen.V280.Document
import Evergreen.V280.Parser.Language
import Evergreen.V280.Types as Old
import Evergreen.V280.User
import Evergreen.V281.Authentication
import Evergreen.V281.Credentials
import Evergreen.V281.Document
import Evergreen.V281.Parser.Language
import Evergreen.V281.Types as New
import Evergreen.V281.User
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


injectLang : Evergreen.V280.Parser.Language.Language -> Evergreen.V281.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V280.Parser.Language.L0Lang ->
            Evergreen.V281.Parser.Language.L0Lang

        Evergreen.V280.Parser.Language.MicroLaTeXLang ->
            Evergreen.V281.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V281.Parser.Language.L0Lang


injectDocument : Evergreen.V280.Document.Document -> Evergreen.V281.Document.Document
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
    , share = Evergreen.V281.Document.NotShared
    }


identityCredentials : Evergreen.V280.Credentials.Credentials -> Evergreen.V281.Credentials.Credentials
identityCredentials (Evergreen.V280.Credentials.V1 a b) =
    Evergreen.V281.Credentials.V1 a b


identityUserData : Evergreen.V280.Authentication.UserData -> Evergreen.V281.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V280.User.User -> Evergreen.V281.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V281.Parser.Language.L0Lang, group = Nothing }
    }


identityAuthenticationDict : Evergreen.V280.Authentication.AuthenticationDict -> Evergreen.V281.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
