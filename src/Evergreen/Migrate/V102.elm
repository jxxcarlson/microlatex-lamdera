module Evergreen.Migrate.V102 exposing (..)

{-| For future reference I describe a mostly mechanical procedure for constructing
the migration defined below.


## The first change: type Language

One change in one type created a cascade
of changes that had to be handled in the backend model. The culprit was
the 'Language' type in module 'Parser.Language' — one variant, XMarkdownLang,
was added.

    V99
    ---
    type Language
        = L0Lang
        | MicroLaTeXLang

    V102
    ---
    type Language
        = L0Lang
        | MicroLaTeXLang
        | XMarkdownLang

This change is handled by the function

    injectLang : Evergreen.V99.Parser.Language.Language -> Evergreen.V102.Parser.Language.Language
    injectLang lang =
        case lang of
            Evergreen.V99.Parser.Language.L0Lang ->
                Evergreen.V102.Parser.Language.L0Lang

            Evergreen.V99.Parser.Language.MicroLaTeXLang ->
                Evergreen.V102.Parser.Language.MicroLaTeXLang

Notice that not much is going on in this function: it "injects" values of one
type what one mighty think of as an enlargement of that type.


## Second change: the Document type alias.

The Document type alias is a record, one field of which is langauge, of type Language.
Consequently we need to map values of the V99 version of Document to the V102 version:

    injectDocument : Evergreen.V99.Document.Document -> Evergreen.V102.Document.Document
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
        }

Notice that all of the mappings on the field level are trivial except for
the language field, where we appply function injectLang.


## Dictionaries and lists

One lifts injectDocument from values of type Document to values of type
'List Document\` and type 'Dict String Document' using various mapping
functions:

    documents =
        List.map injectDocument old.documents

    documentDict =
        Dict.map (\_ doc -> injectDocument doc) old.documentDict


## Authentication

Nothing changed here, but there is a custom type which has to be
handled:

    identityCredentials : Evergreen.V99.Credentials.Credentials -> Evergreen.V102.Credentials.Credentials
    identityCredentials (Evergreen.V99.Credentials.V1 a b) =
        Evergreen.V102.Credentials.V1 a b

In this case, the types changed even though the underlying data did not. We must
write code to handle this. The mapping on credentials propagates to a mapping
on dictionaries via a function identityUserData and then identityAuthenticationDict.

I would think that the procedure described above could be mechanized so as to provide
a tool for building migrations.

-}

import Dict
import Evergreen.V102.Authentication
import Evergreen.V102.Credentials
import Evergreen.V102.Document
import Evergreen.V102.Parser.Language
import Evergreen.V102.Types as New
import Evergreen.V99.Authentication
import Evergreen.V99.Credentials
import Evergreen.V99.Document
import Evergreen.V99.Parser.Language
import Evergreen.V99.Types as Old
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


injectLang : Evergreen.V99.Parser.Language.Language -> Evergreen.V102.Parser.Language.Language
injectLang lang =
    case lang of
        Evergreen.V99.Parser.Language.L0Lang ->
            Evergreen.V102.Parser.Language.L0Lang

        Evergreen.V99.Parser.Language.MicroLaTeXLang ->
            Evergreen.V102.Parser.Language.MicroLaTeXLang


injectDocument : Evergreen.V99.Document.Document -> Evergreen.V102.Document.Document
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
    }


identityCredentials : Evergreen.V99.Credentials.Credentials -> Evergreen.V102.Credentials.Credentials
identityCredentials (Evergreen.V99.Credentials.V1 a b) =
    Evergreen.V102.Credentials.V1 a b


identityUserData : Evergreen.V99.Authentication.UserData -> Evergreen.V102.Authentication.UserData
identityUserData oldUserData =
    { user = oldUserData.user
    , credentials = identityCredentials oldUserData.credentials
    }


identityAuthenticationDict : Evergreen.V99.Authentication.AuthenticationDict -> Evergreen.V102.Authentication.AuthenticationDict
identityAuthenticationDict oldAuthenticationDict =
    Dict.map (\username userdata -> identityUserData userdata) oldAuthenticationDict
