module Evergreen.Migrate.V515 exposing (..)

-- 502 >> 509
-- 503 >> 515

import BoundedDeque
import Deque
import Dict
import Evergreen.V509.Authentication
import Evergreen.V509.Credentials
import Evergreen.V509.Document
import Evergreen.V509.Parser.Language
import Evergreen.V509.Types as Old
import Evergreen.V509.User
import Evergreen.V515.Authentication
import Evergreen.V515.Credentials
import Evergreen.V515.Document
import Evergreen.V515.Parser.Language
import Evergreen.V515.Types as New
import Evergreen.V515.User
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


injectLang : Evergreen.V509.Parser.Language.Language -> Evergreen.V515.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V509.Parser.Language.L0Lang ->
            Evergreen.V515.Parser.Language.L0Lang

        Evergreen.V509.Parser.Language.MicroLaTeXLang ->
            Evergreen.V515.Parser.Language.MicroLaTeXLang

        _ ->
            Evergreen.V515.Parser.Language.L0Lang


injectDocument : Evergreen.V509.Document.Document -> Evergreen.V515.Document.Document
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
    --, share = Evergreen.V515.Document.NotShared
    , isShared = False
    , sharedWith =
        { readers = []
        , editors = []
        }
    , handling = Evergreen.V515.Document.DHStandard
    , status = Evergreen.V515.Document.DSReadOnly
    }


identityCredentials : Evergreen.V509.Credentials.Credentials -> Evergreen.V515.Credentials.Credentials
identityCredentials (Evergreen.V509.Credentials.V1 a b) =
    Evergreen.V515.Credentials.V1 a b


identityUserData : Evergreen.V509.Authentication.UserData -> Evergreen.V515.Authentication.UserData
identityUserData oldUserData =
    { user = injectuser oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


injectuser : Evergreen.V509.User.User -> Evergreen.V515.User.User
injectuser oldUser =
    { username = oldUser.username
    , id = oldUser.id
    , realname = oldUser.realname
    , email = oldUser.email
    , created = oldUser.created
    , modified = oldUser.modified
    , docs = BoundedDeque.empty 15
    , preferences = { language = Evergreen.V515.Parser.Language.L0Lang, group = Nothing }
    , chatGroups = []
    , sharedDocuments = []
    , sharedDocumentAuthors = Set.empty
    , pings = []
    }


identityAuthenticationDict : Evergreen.V509.Authentication.AuthenticationDict -> Evergreen.V515.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
