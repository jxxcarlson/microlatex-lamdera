module Evergreen.Migrate.V382 exposing (..)

-- 280 >> 378 (Old)
-- 281 >> 382 (New)

import BoundedDeque
import Dict
import Evergreen.V378.Authentication
import Evergreen.V378.Credentials
import Evergreen.V378.Document
import Evergreen.V378.Parser.Language
import Evergreen.V378.Types as Old
import Evergreen.V378.User
import Evergreen.V382.Authentication
import Evergreen.V382.Credentials
import Evergreen.V382.Document
import Evergreen.V382.Parser.Language
import Evergreen.V382.Types as New
import Evergreen.V382.User
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


injectLang : Evergreen.V378.Parser.Language.Language -> Evergreen.V382.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V378.Parser.Language.L0Lang ->
            Evergreen.V382.Parser.Language.L0Lang

        Evergreen.V378.Parser.Language.MicroLaTeXLang ->
            Evergreen.V382.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V382.Parser.Language.L0Lang


injectDocument : Evergreen.V378.Document.Document -> Evergreen.V382.Document.Document
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
    , share = Evergreen.V382.Document.NotShared
    }


identityCredentials : Evergreen.V378.Credentials.Credentials -> Evergreen.V382.Credentials.Credentials
identityCredentials (Evergreen.V378.Credentials.V1 a b) =
    Evergreen.V382.Credentials.V1 a b


identityUserData : Evergreen.V378.Authentication.UserData -> Evergreen.V382.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V378.User.User -> Evergreen.V382.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V382.Parser.Language.L0Lang, group = Nothing }
    , chatGroups = []
    , sharedDocuments = []
    , sharedDocumentAuthors = Set.empty
    }


identityAuthenticationDict : Evergreen.V378.Authentication.AuthenticationDict -> Evergreen.V382.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
