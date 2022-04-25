module Evergreen.Migrate.V494 exposing (..)

import BoundedDeque
import Dict
import Evergreen.V487.Authentication
import Evergreen.V487.Credentials
import Evergreen.V487.Document
import Evergreen.V487.Parser.Language
import Evergreen.V487.Types as Old
import Evergreen.V487.User
import Evergreen.V494.Authentication
import Evergreen.V494.Credentials
import Evergreen.V494.Document
import Evergreen.V494.Parser.Language
import Evergreen.V494.Types as New
import Evergreen.V494.User
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


injectLang : Evergreen.V487.Parser.Language.Language -> Evergreen.V494.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V487.Parser.Language.L0Lang ->
            Evergreen.V494.Parser.Language.L0Lang

        Evergreen.V487.Parser.Language.MicroLaTeXLang ->
            Evergreen.V494.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V494.Parser.Language.L0Lang


injectDocument : Evergreen.V487.Document.Document -> Evergreen.V494.Document.Document
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
    , share = Evergreen.V494.Document.NotShared
    , handling = Evergreen.V494.Document.DHStandard
    , status = Evergreen.V494.Document.DSReadOnly
    }


identityCredentials : Evergreen.V487.Credentials.Credentials -> Evergreen.V494.Credentials.Credentials
identityCredentials (Evergreen.V487.Credentials.V1 a b) =
    Evergreen.V494.Credentials.V1 a b


identityUserData : Evergreen.V487.Authentication.UserData -> Evergreen.V494.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V487.User.User -> Evergreen.V494.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V494.Parser.Language.L0Lang, group = Nothing }
    , chatGroups = []
    , sharedDocuments = []
    , sharedDocumentAuthors = Set.empty
    , pings = []
    }


identityAuthenticationDict : Evergreen.V487.Authentication.AuthenticationDict -> Evergreen.V494.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
