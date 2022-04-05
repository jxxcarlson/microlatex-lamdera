module Types exposing
    ( AbstractDict
    , AbstractDictOLD
    , ActiveDocList(..)
    , AppMode(..)
    , AuthorDict
    , BackendModel
    , BackendMsg(..)
    , BackupOLD
    , DocId
    , DocLoaded(..)
    , DocumentDeleteState(..)
    , DocumentDict
    , DocumentLink
    , DocumentList(..)
    , FrontendModel
    , FrontendMsg(..)
    , MaximizedIndex(..)
    , Message
    , MessageStatus(..)
    , PhoneMode(..)
    , PopupState(..)
    , PopupStatus(..)
    , PopupWindow(..)
    , PrintingState(..)
    , PublicIdDict
    , SearchTerm(..)
    , SidebarState(..)
    , SignupState(..)
    , SortMode(..)
    , SystemDocPermissions(..)
    , TagSelection(..)
    , ToBackend(..)
    , ToFrontend(..)
    , UserId
    , UsersDocumentsDict
    )

import Abstract exposing (Abstract, AbstractOLD)
import Authentication exposing (AuthenticationDict)
import Browser exposing (UrlRequest)
import Browser.Dom as Dom
import Browser.Navigation
import Compiler.DifferentialParser
import Debounce exposing (Debounce)
import Dict exposing (Dict)
import Document exposing (Document)
import Element as Color
import File exposing (File)
import Http
import Keyboard
import Lamdera
import Parser.Block exposing (ExpressionBlock)
import Parser.Language exposing (Language)
import Random
import Render.Msg
import Time
import Url exposing (Url)
import User exposing (User)


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , url : Url
    , messages : List Message

    -- ADMIN
    , statusReport : List String
    , inputSpecial : String
    , userList : List ( User, Int )

    -- USER
    , currentUser : Maybe User
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputLanguage : Language
    , tagDict : Dict String (List { id : String, title : String })
    , documentList : DocumentList

    -- UI
    , appMode : AppMode
    , windowWidth : Int
    , windowHeight : Int
    , popupStatus : PopupStatus
    , showEditor : Bool
    , authorId : String
    , phoneMode : PhoneMode
    , pressedKeys : List Keyboard.Key
    , activeDocList : ActiveDocList
    , maximizedIndex : MaximizedIndex
    , sidebarState : SidebarState
    , tagSelection : TagSelection
    , signupState : SignupState
    , popupState : PopupState

    -- SYNC
    , foundIds : List String
    , foundIdIndex : Int
    , selectedId : String
    , syncRequestIndex : Int
    , linenumber : Int
    , doSync : Bool

    -- DOCUMENT
    , docLoaded : DocLoaded
    , documentsCreatedCounter : Int
    , initialText : String
    , sourceText : String
    , inputTitle : String

    --, ast : Markup.SyntaxTree
    , editRecord : Compiler.DifferentialParser.EditRecord
    , tableOfContents : List ExpressionBlock
    , title : String
    , searchCount : Int
    , searchSourceText : String
    , lineNumber : Int
    , permissions : SystemDocPermissions
    , debounce : Debounce String
    , currentDocument : Maybe Document
    , currentMasterDocument : Maybe Document
    , documents : List Document
    , inputSearchKey : String
    , inputSearchTagsKey : String
    , inputReaders : String
    , inputEditors : String
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , publicDocuments : List Document
    , deleteDocumentState : DocumentDeleteState
    , sortMode : SortMode
    , language : Language
    }


type alias Message =
    { content : String, status : MessageStatus }


type MessageStatus
    = MSNormal
    | MSWarning
    | MSGreen
    | MSError


type PopupState
    = NoPopup
    | LanguageMenuPopup
    | NewDocumentPopup
    | SharePopup


type TagSelection
    = TagNeither
    | TagPublic
    | TagUser


type MaximizedIndex
    = MMyDocs
    | MPublicDocs


type ActiveDocList
    = PublicDocsList
    | PrivateDocsList
    | Both


type SortMode
    = SortAlphabetically
    | SortByMostRecent


type DocLoaded
    = NotLoaded


type AppMode
    = UserMode
    | AdminMode


type PhoneMode
    = PMShowDocument
    | PMShowDocumentList


type PopupWindow
    = AdminPopup


type PopupStatus
    = PopupClosed


type alias BackendModel =
    { message : String
    , currentTime : Time.Posix

    -- RANDOM
    , randomSeed : Random.Seed
    , uuidCount : Int
    , randomAtmosphericInt : Maybe Int

    -- USER
    , authenticationDict : AuthenticationDict

    -- DATA
    , documentDict : DocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , publicDocuments : List Document

    -- DOCUMENT
    , documents : List Document
    }


type alias DocumentLink =
    { digest : String, label : String, url : String }



-- Entries for the first three dictionaries are created when a document
-- is created.


{-| author's doc id -> docId; enables author access to doc via a link
-}
type alias AuthorDict =
    Dict String String


{-| public's doc id -> docId; enables public access to doc via a link
-}
type alias PublicIdDict =
    Dict String String


{-| docId -> Document
-}
type alias DocumentDict =
    Dict String Document


{-| User id -> List docId
-}
type alias UsersDocumentsDict =
    Dict UserId (List DocId)



-- The document abstract is updated every time a document is saved.


{-| docId -> Document abstracts
-}
type alias AbstractDict =
    Dict String Abstract


type alias AbstractDictOLD =
    Dict String AbstractOLD


type alias UserId =
    String


type alias DocId =
    String


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
      -- UI
    | SetAppMode AppMode
    | GotNewWindowDimensions Int Int
    | GotViewport Dom.Viewport
    | SetViewPortForElement (Result Dom.Error ( Dom.Element, Dom.Viewport ))
    | ChangePopupStatus PopupStatus
    | CloseEditor
    | OpenEditor
    | Home
    | KeyMsg Keyboard.Msg
      -- ADMIN
    | InputSpecial String
    | RunSpecial
    | GoGetUserList
      -- USER
    | SignIn
    | SetSignupState SignupState
    | DoSignUp
    | SignOut
    | InputUsername String
    | InputPassword String
    | InputPasswordAgain String
    | InputRealname String
    | InputEmail String
    | SetUserLanguage Language
      -- SYNC
    | SelectedText String
    | SyncLR
    | StartSync
    | NextSync
    | SendSyncLR
    | GetSelection String
      -- UI
    | ToggleActiveDocList
    | CloseCollectionIndex
    | ToggleIndexSize
    | ToggleSideBar
    | ChangePopup PopupState
      -- DOC
    | ShareDocument
    | DoShare
    | GetPinnedDocuments
    | SetLanguage Bool Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent SystemDocPermissions Document
    | ShowTOCInPhone
    | InputSearchSource String
    | InputText String
    | InputTitle String
    | InputReaders String
    | InputEditors String
    | DebounceMsg Debounce.Msg
    | Saved String
    | InputSearchKey String
    | InputSearchTagsKey String
    | Search
    | SearchText
    | InputAuthorId String
    | NewDocument
    | SetDocumentAsCurrent SystemDocPermissions Document
    | SetPublic Document Bool
    | AskFoDocumentById String
    | AskForDocumentByAuthorId
    | DeleteDocument
    | SetDeleteDocumentState DocumentDeleteState
    | Render Render.Msg.MarkupMsg
    | SetSortMode SortMode
    | SelectList DocumentList
    | GetUserTags String
    | GetPublicTags
      -- Export
    | ExportToMarkdown
    | ExportToLaTeX
    | ExportTo Language
    | Export
      -- PDF
    | PrintToPDF
    | GotPdfLink (Result Http.Error String)
    | ChangePrintingState PrintingState
    | FinallyDoCleanPrintArtefacts String
      ---
    | Help String


type DocumentList
    = WorkingList
    | StandardList


type SidebarState
    = SidebarIn
    | SidebarOut


type PrintingState
    = PrintWaiting
    | PrintProcessing
    | PrintReady


type DocumentDeleteState
    = WaitingForDeleteAction
    | CanDelete


type SearchTerm
    = Query String


type ToBackend
    = --ADMIN
      RunTask
    | GetStatus
    | GetUserList
      -- USER
    | SignInBE String String
    | SignUpBE String Language String String String
    | UpdateUserWith User
      -- DOCUMENT
    | RequestRefresh String
    | RequestLock String String -- Username, DocumentId
    | RequestUnlock String String -- Username, DocumentId
    | UnlockDocuments (Maybe String)
    | GetHomePage String
    | FetchDocumentById String (Maybe String)
    | GetPublicDocuments (Maybe String)
    | SaveDocument Document
    | GetDocumentByAuthorId String
    | GetDocumentByPublicId String
    | GetDocumentById String
    | CreateDocument (Maybe User) Document
    | ApplySpecial User String
    | SearchForDocuments (Maybe String) String
    | DeleteDocumentBE Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type SignupState
    = ShowSignUpForm
    | HideSignUpForm


type BackendMsg
    = GotAtomsphericRandomNumber (Result Http.Error String)
    | DelaySendingDocument Lamdera.ClientId Document
    | Tick Time.Posix


type ToFrontend
    = -- ADMIN
      SendBackupData String
    | GotUserList (List ( User, Int ))
      -- USEr
    | UserSignedUp User
      -- DOCUMENT
    | AcceptUserTags (Dict String (List { id : String, title : String }))
    | AcceptPublicTags (Dict String (List { id : String, title : String }))
    | SendDocument SystemDocPermissions Document
    | SendDocuments (List Document)
    | SendMessage Message
    | StatusReport (List String)
    | SetShowEditor Bool
    | GotPublicDocuments (List Document)


type SystemDocPermissions
    = SystemReadOnly
    | SystemCanEdit


type alias BackupOLD =
    { message : String
    , currentTime : Time.Posix

    -- RANDOM
    , randomSeed : Random.Seed
    , uuidCount : Int
    , randomAtmosphericInt : Maybe Int

    -- USER
    , authenticationDict : Authentication.AuthenticationDict

    -- DATA
    , documentDict : DocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , publicDocuments : List Document

    --
    ---- DOCUMENTS
    , documents : List Document
    }
