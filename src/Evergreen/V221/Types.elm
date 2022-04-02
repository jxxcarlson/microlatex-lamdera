module Evergreen.V221.Types exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation
import Debounce
import Dict
import Evergreen.V221.Abstract
import Evergreen.V221.Authentication
import Evergreen.V221.Compiler.DifferentialParser
import Evergreen.V221.Document
import Evergreen.V221.Parser.Block
import Evergreen.V221.Parser.Language
import Evergreen.V221.Render.Msg
import Evergreen.V221.User
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
    , currentUser : Maybe Evergreen.V221.User.User
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputLanguage : Evergreen.V221.Parser.Language.Language
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
    , editRecord : Evergreen.V221.Compiler.DifferentialParser.EditRecord
    , tableOfContents : List Evergreen.V221.Parser.Block.ExpressionBlock
    , title : String
    , searchCount : Int
    , searchSourceText : String
    , lineNumber : Int
    , permissions : DocPermissions
    , debounce : Debounce.Debounce String
    , currentDocument : Maybe Evergreen.V221.Document.Document
    , currentMasterDocument : Maybe Evergreen.V221.Document.Document
    , documents : List Evergreen.V221.Document.Document
    , inputSearchKey : String
    , inputSearchTagsKey : String
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , publicDocuments : List Evergreen.V221.Document.Document
    , deleteDocumentState : DocumentDeleteState
    , sortMode : SortMode
    , language : Evergreen.V221.Parser.Language.Language
    }


type alias DocumentDict =
    Dict.Dict String Evergreen.V221.Document.Document


type alias AuthorDict =
    Dict.Dict String String


type alias PublicIdDict =
    Dict.Dict String String


type alias AbstractDict =
    Dict.Dict String Evergreen.V221.Abstract.Abstract


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
    , authenticationDict : Evergreen.V221.Authentication.AuthenticationDict
    , documentDict : DocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , publicDocuments : List Evergreen.V221.Document.Document
    , documents : List Evergreen.V221.Document.Document
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
    | SetUserLanguage Evergreen.V221.Parser.Language.Language
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
    | GetPinnedDocuments
    | SetLanguage Bool Evergreen.V221.Parser.Language.Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent DocPermissions Evergreen.V221.Document.Document
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
    | SetDocumentAsCurrent DocPermissions Evergreen.V221.Document.Document
    | SetPublic Evergreen.V221.Document.Document Bool
    | AskFoDocumentById String
    | AskForDocumentByAuthorId
    | DeleteDocument
    | SetDeleteDocumentState DocumentDeleteState
    | Render Evergreen.V221.Render.Msg.MarkupMsg
    | SetSortMode SortMode
    | SelectList DocumentList
    | GetUserTags String
    | GetPublicTags
    | ExportToMarkdown
    | ExportToLaTeX
    | ExportTo Evergreen.V221.Parser.Language.Language
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
    | SignUpBE String Evergreen.V221.Parser.Language.Language String String String
    | UpdateUserWith Evergreen.V221.User.User
    | GetHomePage String
    | FetchDocumentById String (Maybe String)
    | GetPublicDocuments
    | SaveDocument (Maybe Evergreen.V221.User.User) Evergreen.V221.Document.Document
    | GetDocumentByAuthorId String
    | GetDocumentByPublicId String
    | GetDocumentById String
    | CreateDocument (Maybe Evergreen.V221.User.User) Evergreen.V221.Document.Document
    | ApplySpecial Evergreen.V221.User.User String
    | SearchForDocuments (Maybe String) String
    | DeleteDocumentBE Evergreen.V221.Document.Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type BackendMsg
    = GotAtomsphericRandomNumber (Result Http.Error String)
    | Tick Time.Posix


type ToFrontend
    = SendBackupData String
    | UserSignedUp Evergreen.V221.User.User
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
    | SendDocument DocPermissions Evergreen.V221.Document.Document
    | SendDocuments (List Evergreen.V221.Document.Document)
    | SendMessage String
    | StatusReport (List String)
    | SetShowEditor Bool
    | GotPublicDocuments (List Evergreen.V221.Document.Document)
