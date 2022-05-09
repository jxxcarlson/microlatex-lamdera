module Evergreen.Migrate.V503 exposing (..)

-- 487 >> 502
-- 494 >> 503

import BoundedDeque
import Deque
import Dict
import Evergreen.V502.Authentication
import Evergreen.V502.Credentials
import Evergreen.V502.Document
import Evergreen.V502.Parser.Language
import Evergreen.V502.Types as Old
import Evergreen.V502.User
import Evergreen.V503.Authentication
import Evergreen.V503.Credentials
import Evergreen.V503.Document
import Evergreen.V503.Parser.Language
import Evergreen.V503.Types as New
import Evergreen.V503.User
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
          , connectionDict = old.connectionDict
          , sharedDocumentDict = Dict.empty
          , chatDict = old.chatDict
          , chatGroupDict = old.chatGroupDict
          , editEvents = Deque.empty
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


injectLang : Evergreen.V502.Parser.Language.Language -> Evergreen.V503.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V502.Parser.Language.L0Lang ->
            Evergreen.V503.Parser.Language.L0Lang

        Evergreen.V502.Parser.Language.MicroLaTeXLang ->
            Evergreen.V503.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V503.Parser.Language.L0Lang


injectDocument : Evergreen.V502.Document.Document -> Evergreen.V503.Document.Document
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
    , currentEditorList = []

    -- , currentEditor = Nothing
    --, share = Evergreen.V503.Document.NotShared
    , isShared = False
    , sharedWith =
        { readers = []
        , editors = []
        }
    , handling = Evergreen.V503.Document.DHStandard
    , status = Evergreen.V503.Document.DSReadOnly
    }


identityCredentials : Evergreen.V502.Credentials.Credentials -> Evergreen.V503.Credentials.Credentials
identityCredentials (Evergreen.V502.Credentials.V1 a b) =
    Evergreen.V503.Credentials.V1 a b


identityUserData : Evergreen.V502.Authentication.UserData -> Evergreen.V503.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V502.User.User -> Evergreen.V503.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V503.Parser.Language.L0Lang, group = Nothing }
    , chatGroups = []
    , sharedDocuments = []
    , sharedDocumentAuthors = Set.empty
    , pings = []
    }


identityAuthenticationDict : Evergreen.V502.Authentication.AuthenticationDict -> Evergreen.V503.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
