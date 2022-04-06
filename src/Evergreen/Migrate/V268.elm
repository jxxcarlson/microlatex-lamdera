module Evergreen.Migrate.V268 exposing (..)

-- FROM V250

import BoundedDeque
import Dict
import Evergreen.V260.Authentication
import Evergreen.V260.Credentials
import Evergreen.V260.Document
import Evergreen.V260.Parser.Language
import Evergreen.V260.Types as Old
import Evergreen.V260.User
import Evergreen.V268.Authentication
import Evergreen.V268.Credentials
import Evergreen.V268.Document
import Evergreen.V268.Parser.Language
import Evergreen.V268.Types as New
import Evergreen.V268.User
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


injectLang : Evergreen.V260.Parser.Language.Language -> Evergreen.V268.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V260.Parser.Language.L0Lang ->
            Evergreen.V268.Parser.Language.L0Lang

        Evergreen.V260.Parser.Language.MicroLaTeXLang ->
            Evergreen.V268.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V268.Parser.Language.L0Lang


injectDocument : Evergreen.V260.Document.Document -> Evergreen.V268.Document.Document
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
    , share = Evergreen.V268.Document.NotShared
    }


identityCredentials : Evergreen.V260.Credentials.Credentials -> Evergreen.V268.Credentials.Credentials
identityCredentials (Evergreen.V260.Credentials.V1 a b) =
    Evergreen.V268.Credentials.V1 a b


identityUserData : Evergreen.V260.Authentication.UserData -> Evergreen.V268.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V260.User.User -> Evergreen.V268.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V268.Parser.Language.L0Lang }
    }


identityAuthenticationDict : Evergreen.V260.Authentication.AuthenticationDict -> Evergreen.V268.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
