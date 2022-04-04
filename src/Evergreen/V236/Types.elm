module Evergreen.V236.Types exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation
import Debounce
import Dict
import Evergreen.V236.Abstract
import Evergreen.V236.Authentication
import Evergreen.V236.Compiler.DifferentialParser
import Evergreen.V236.Document
import Evergreen.V236.Parser.Block
import Evergreen.V236.Parser.Language
import Evergreen.V236.Render.Msg
import Evergreen.V236.User
import Http
import Keyboard
import Random
import Time
import Url


type MessageStatus
    = MSNormal
    | MSWarning
    | MSGreen
    | MSError


type alias Message =
    { content : String
    , status : MessageStatus
    }


type DocumentList
    = WorkingList
    | StandardList


type AppMode
    = UserMode
    | AdminMode


type PopupStatus
    = PopupClosed


type PhoneMode
    = PMShowDocument
    | PMShowDocumentList


type ActiveDocList
    = PublicDocsList
    | PrivateDocsList
    | Both


type MaximizedIndex
    = MMyDocs
    | MPublicDocs


type SidebarState
    = SidebarIn
    | SidebarOut


type TagSelection
    = TagNeither
    | TagPublic
    | TagUser


type SignupState
    = ShowSignUpForm
    | HideSignUpForm


type PopupState
    = NoPopup
    | LanguageMenuPopup
    | NewDocumentPopup
    | SharePopup


type DocLoaded
    = NotLoaded


type SystemDocPermissions
    = SystemReadOnly
    | SystemCanEdit


type PrintingState
    = PrintWaiting
    | PrintProcessing
    | PrintReady


type DocumentDeleteState
    = WaitingForDeleteAction
    | CanDelete


type SortMode
    = SortAlphabetically
    | SortByMostRecent


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , messages : List Message
    , statusReport : List String
    , inputSpecial : String
    , userList : List ( Evergreen.V236.User.User, Int )
    , currentUser : Maybe Evergreen.V236.User.User
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputLanguage : Evergreen.V236.Parser.Language.Language
    , tagDict :
        Dict.Dict
            String
            (List
                { id : String
                , title : String
                }
            )
    , documentList : DocumentList
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
    , foundIds : List String
    , foundIdIndex : Int
    , selectedId : String
    , syncRequestIndex : Int
    , linenumber : Int
    , doSync : Bool
    , docLoaded : DocLoaded
    , documentsCreatedCounter : Int
    , initialText : String
    , sourceText : String
    , inputTitle : String
    , editRecord : Evergreen.V236.Compiler.DifferentialParser.EditRecord
    , tableOfContents : List Evergreen.V236.Parser.Block.ExpressionBlock
    , title : String
    , searchCount : Int
    , searchSourceText : String
    , lineNumber : Int
    , permissions : SystemDocPermissions
    , debounce : Debounce.Debounce String
    , currentDocument : Maybe Evergreen.V236.Document.Document
    , currentMasterDocument : Maybe Evergreen.V236.Document.Document
    , documents : List Evergreen.V236.Document.Document
    , inputSearchKey : String
    , inputSearchTagsKey : String
    , inputReaders : String
    , inputEditors : String
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , publicDocuments : List Evergreen.V236.Document.Document
    , deleteDocumentState : DocumentDeleteState
    , sortMode : SortMode
    , language : Evergreen.V236.Parser.Language.Language
    }


type alias DocumentDict =
    Dict.Dict String Evergreen.V236.Document.Document


type alias AuthorDict =
    Dict.Dict String String


type alias PublicIdDict =
    Dict.Dict String String


type alias AbstractDict =
    Dict.Dict String Evergreen.V236.Abstract.Abstract


type alias UserId =
    String


type alias DocId =
    String


type alias UsersDocumentsDict =
    Dict.Dict UserId (List DocId)


type alias BackendModel =
    { message : String
    , currentTime : Time.Posix
    , randomSeed : Random.Seed
    , uuidCount : Int
    , randomAtmosphericInt : Maybe Int
    , authenticationDict : Evergreen.V236.Authentication.AuthenticationDict
    , documentDict : DocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , publicDocuments : List Evergreen.V236.Document.Document
    , documents : List Evergreen.V236.Document.Document
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | SetAppMode AppMode
    | GotNewWindowDimensions Int Int
    | GotViewport Browser.Dom.Viewport
    | SetViewPortForElement (Result Browser.Dom.Error ( Browser.Dom.Element, Browser.Dom.Viewport ))
    | ChangePopupStatus PopupStatus
    | CloseEditor
    | OpenEditor
    | Home
    | KeyMsg Keyboard.Msg
    | InputSpecial String
    | RunSpecial
    | GoGetUserList
    | SignIn
    | SetSignupState SignupState
    | DoSignUp
    | SignOut
    | InputUsername String
    | InputPassword String
    | InputPasswordAgain String
    | InputRealname String
    | InputEmail String
    | SetUserLanguage Evergreen.V236.Parser.Language.Language
    | SelectedText String
    | SyncLR
    | StartSync
    | NextSync
    | SendSyncLR
    | GetSelection String
    | ToggleActiveDocList
    | CloseCollectionIndex
    | ToggleIndexSize
    | ToggleSideBar
    | ChangePopup PopupState
    | ShareDocument
    | DoShare
    | GetPinnedDocuments
    | SetLanguage Bool Evergreen.V236.Parser.Language.Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent SystemDocPermissions Evergreen.V236.Document.Document
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
    | SetDocumentAsCurrent SystemDocPermissions Evergreen.V236.Document.Document
    | SetPublic Evergreen.V236.Document.Document Bool
    | AskFoDocumentById String
    | AskForDocumentByAuthorId
    | DeleteDocument
    | SetDeleteDocumentState DocumentDeleteState
    | Render Evergreen.V236.Render.Msg.MarkupMsg
    | SetSortMode SortMode
    | SelectList DocumentList
    | GetUserTags String
    | GetPublicTags
    | ExportToMarkdown
    | ExportToLaTeX
    | ExportTo Evergreen.V236.Parser.Language.Language
    | Export
    | PrintToPDF
    | GotPdfLink (Result Http.Error String)
    | ChangePrintingState PrintingState
    | FinallyDoCleanPrintArtefacts String
    | Help String


type ToBackend
    = RunTask
    | GetStatus
    | GetUserList
    | SignInBE String String
    | SignUpBE String Evergreen.V236.Parser.Language.Language String String String
    | UpdateUserWith Evergreen.V236.User.User
    | RequestLock String String
    | RequestUnlock String String
    | UnlockDocuments (Maybe String)
    | GetHomePage String
    | FetchDocumentById String (Maybe String)
    | GetPublicDocuments (Maybe String)
    | SaveDocument Evergreen.V236.Document.Document
    | GetDocumentByAuthorId String
    | GetDocumentByPublicId String
    | GetDocumentById String
    | CreateDocument (Maybe Evergreen.V236.User.User) Evergreen.V236.Document.Document
    | ApplySpecial Evergreen.V236.User.User String
    | SearchForDocuments (Maybe String) String
    | DeleteDocumentBE Evergreen.V236.Document.Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type BackendMsg
    = GotAtomsphericRandomNumber (Result Http.Error String)
    | Tick Time.Posix


type ToFrontend
    = SendBackupData String
    | GotUserList (List ( Evergreen.V236.User.User, Int ))
    | UserSignedUp Evergreen.V236.User.User
    | AcceptUserTags
        (Dict.Dict
            String
            (List
                { id : String
                , title : String
                }
            )
        )
    | AcceptPublicTags
        (Dict.Dict
            String
            (List
                { id : String
                , title : String
                }
            )
        )
    | SendDocument SystemDocPermissions Evergreen.V236.Document.Document
    | SendDocuments (List Evergreen.V236.Document.Document)
    | SendMessage Message
    | StatusReport (List String)
    | SetShowEditor Bool
    | GotPublicDocuments (List Evergreen.V236.Document.Document)
