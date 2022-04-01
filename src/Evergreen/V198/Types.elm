module Evergreen.V198.Types exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation
import Debounce
import Dict
import Evergreen.V198.Abstract
import Evergreen.V198.Authentication
import Evergreen.V198.Compiler.DifferentialParser
import Evergreen.V198.Document
import Evergreen.V198.Parser.Block
import Evergreen.V198.Parser.Language
import Evergreen.V198.Render.Msg
import Evergreen.V198.User
import Http
import Keyboard
import Random
import Time
import Url


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


type DocLoaded
    = NotLoaded


type DocPermissions
    = ReadOnly
    | CanEdit


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
    , message : String
    , statusReport : List String
    , inputSpecial : String
    , currentUser : Maybe Evergreen.V198.User.User
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputLanguage : Evergreen.V198.Parser.Language.Language
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
    , editRecord : Evergreen.V198.Compiler.DifferentialParser.EditRecord
    , tableOfContents : List Evergreen.V198.Parser.Block.ExpressionBlock
    , title : String
    , searchCount : Int
    , searchSourceText : String
    , lineNumber : Int
    , permissions : DocPermissions
    , debounce : Debounce.Debounce String
    , currentDocument : Maybe Evergreen.V198.Document.Document
    , currentMasterDocument : Maybe Evergreen.V198.Document.Document
    , documents : List Evergreen.V198.Document.Document
    , inputSearchKey : String
    , inputSearchTagsKey : String
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , publicDocuments : List Evergreen.V198.Document.Document
    , deleteDocumentState : DocumentDeleteState
    , sortMode : SortMode
    , language : Evergreen.V198.Parser.Language.Language
    }


type alias DocumentDict =
    Dict.Dict String Evergreen.V198.Document.Document


type alias AuthorDict =
    Dict.Dict String String


type alias PublicIdDict =
    Dict.Dict String String


type alias AbstractDict =
    Dict.Dict String Evergreen.V198.Abstract.Abstract


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
    , authenticationDict : Evergreen.V198.Authentication.AuthenticationDict
    , documentDict : DocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , publicDocuments : List Evergreen.V198.Document.Document
    , documents : List Evergreen.V198.Document.Document
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
    | SignIn
    | SetSignupState SignupState
    | DoSignUp
    | SignOut
    | InputUsername String
    | InputPassword String
    | InputPasswordAgain String
    | InputRealname String
    | InputEmail String
    | SetUserLanguage Evergreen.V198.Parser.Language.Language
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
    | SetLanguage Bool Evergreen.V198.Parser.Language.Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent DocPermissions Evergreen.V198.Document.Document
    | ShowTOCInPhone
    | InputSearchSource String
    | InputText String
    | InputTitle String
    | DebounceMsg Debounce.Msg
    | Saved String
    | InputSearchKey String
    | InputSearchTagsKey String
    | Search
    | SearchText
    | InputAuthorId String
    | NewDocument
    | SetDocumentAsCurrent DocPermissions Evergreen.V198.Document.Document
    | SetPublic Evergreen.V198.Document.Document Bool
    | AskFoDocumentById String
    | AskForDocumentByAuthorId
    | DeleteDocument
    | SetDeleteDocumentState DocumentDeleteState
    | Render Evergreen.V198.Render.Msg.MarkupMsg
    | SetSortMode SortMode
    | SelectList DocumentList
    | GetUserTags String
    | GetPublicTags
    | ExportToMarkdown
    | ExportToLaTeX
    | ExportTo Evergreen.V198.Parser.Language.Language
    | Export
    | PrintToPDF
    | GotPdfLink (Result Http.Error String)
    | ChangePrintingState PrintingState
    | FinallyDoCleanPrintArtefacts String
    | Help String


type ToBackend
    = RunTask
    | GetStatus
    | SignInBE String String
    | SignUpBE String Evergreen.V198.Parser.Language.Language String String String
    | UpdateUserWith Evergreen.V198.User.User
    | GetHomePage String
    | FetchDocumentById String (Maybe String)
    | GetPublicDocuments
    | SaveDocument (Maybe Evergreen.V198.User.User) Evergreen.V198.Document.Document
    | GetDocumentByAuthorId String
    | GetDocumentByPublicId String
    | GetDocumentById String
    | CreateDocument (Maybe Evergreen.V198.User.User) Evergreen.V198.Document.Document
    | ApplySpecial Evergreen.V198.User.User String
    | SearchForDocuments (Maybe String) String
    | DeleteDocumentBE Evergreen.V198.Document.Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type BackendMsg
    = GotAtomsphericRandomNumber (Result Http.Error String)
    | Tick Time.Posix


type ToFrontend
    = SendBackupData String
    | UserSignedUp Evergreen.V198.User.User
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
    | SendDocument DocPermissions Evergreen.V198.Document.Document
    | SendDocuments (List Evergreen.V198.Document.Document)
    | SendMessage String
    | StatusReport (List String)
    | SetShowEditor Bool
    | GotPublicDocuments (List Evergreen.V198.Document.Document)
