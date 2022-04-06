module Evergreen.V269.Types exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation
import Debounce
import Dict
import Evergreen.V269.Abstract
import Evergreen.V269.Authentication
import Evergreen.V269.Compiler.DifferentialParser
import Evergreen.V269.Document
import Evergreen.V269.Parser.Block
import Evergreen.V269.Parser.Language
import Evergreen.V269.Render.Msg
import Evergreen.V269.User
import Evergreen.V269.UserMessage
import Http
import Keyboard
import Lamdera
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


type alias SharedDocument =
    { title : String
    , id : String
    , author : Maybe String
    , share : Evergreen.V269.Document.Share
    , currentEditor : Maybe String
    }


type DocumentList
    = WorkingList
    | StandardList
    | SharedDocumentList


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
    | UserMessagePopup
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
    , userList : List ( Evergreen.V269.User.User, Int )
    , connectedUsers : List String
    , shareDocumentList : List ( String, SharedDocument )
    , userMessage : Maybe Evergreen.V269.UserMessage.UserMessage
    , currentUser : Maybe Evergreen.V269.User.User
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputLanguage : Evergreen.V269.Parser.Language.Language
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
    , editRecord : Evergreen.V269.Compiler.DifferentialParser.EditRecord
    , tableOfContents : List Evergreen.V269.Parser.Block.ExpressionBlock
    , title : String
    , searchCount : Int
    , searchSourceText : String
    , lineNumber : Int
    , permissions : SystemDocPermissions
    , debounce : Debounce.Debounce String
    , currentDocument : Maybe Evergreen.V269.Document.Document
    , currentMasterDocument : Maybe Evergreen.V269.Document.Document
    , documents : List Evergreen.V269.Document.Document
    , inputSearchKey : String
    , inputSearchTagsKey : String
    , inputReaders : String
    , inputEditors : String
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , publicDocuments : List Evergreen.V269.Document.Document
    , deleteDocumentState : DocumentDeleteState
    , sortMode : SortMode
    , language : Evergreen.V269.Parser.Language.Language
    }


type alias DocumentDict =
    Dict.Dict String Evergreen.V269.Document.Document


type alias SharedDocumentDict =
    Dict.Dict String SharedDocument


type alias AuthorDict =
    Dict.Dict String String


type alias PublicIdDict =
    Dict.Dict String String


type alias AbstractDict =
    Dict.Dict String Evergreen.V269.Abstract.Abstract


type alias UserId =
    String


type alias DocId =
    String


type alias UsersDocumentsDict =
    Dict.Dict UserId (List DocId)


type alias ConnectionData =
    { session : Lamdera.SessionId
    , client : Lamdera.ClientId
    }


type alias ConnectionDict =
    Dict.Dict String (List ConnectionData)


type alias BackendModel =
    { message : String
    , currentTime : Time.Posix
    , randomSeed : Random.Seed
    , uuidCount : Int
    , randomAtmosphericInt : Maybe Int
    , authenticationDict : Evergreen.V269.Authentication.AuthenticationDict
    , documentDict : DocumentDict
    , sharedDocumentDict : SharedDocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , publicDocuments : List Evergreen.V269.Document.Document
    , connectionDict : ConnectionDict
    , documents : List Evergreen.V269.Document.Document
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | OpenSharedDocumentList
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
    | ClearConnectionDict
    | SendUserMessage Evergreen.V269.UserMessage.UserMessage
    | SignIn
    | SetSignupState SignupState
    | DoSignUp
    | SignOut
    | InputUsername String
    | InputPassword String
    | InputPasswordAgain String
    | InputRealname String
    | InputEmail String
    | SetUserLanguage Evergreen.V269.Parser.Language.Language
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
    | DismissUserMessage
    | Narrow String Evergreen.V269.Document.Document
    | LockCurrentDocument
    | UnLockCurrentDocument
    | ShareDocument
    | DoShare
    | GetPinnedDocuments
    | SetLanguage Bool Evergreen.V269.Parser.Language.Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent SystemDocPermissions Evergreen.V269.Document.Document
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
    | SetDocumentAsCurrent SystemDocPermissions Evergreen.V269.Document.Document
    | SetPublic Evergreen.V269.Document.Document Bool
    | AskFoDocumentById String
    | AskForDocumentByAuthorId
    | DeleteDocument
    | SetDeleteDocumentState DocumentDeleteState
    | Render Evergreen.V269.Render.Msg.MarkupMsg
    | SetSortMode SortMode
    | SelectList DocumentList
    | GetUserTags String
    | GetPublicTags
    | ExportToMarkdown
    | ExportToLaTeX
    | ExportTo Evergreen.V269.Parser.Language.Language
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
    | GetSharedDocuments String
    | ClearConnectionDictBE
    | DeliverUserMessage Evergreen.V269.UserMessage.UserMessage
    | SignInBE String String
    | SignUpBE String Evergreen.V269.Parser.Language.Language String String String
    | UpdateUserWith Evergreen.V269.User.User
    | Narrowcast String Evergreen.V269.Document.Document
    | RequestRefresh String
    | RequestLock Int String String
    | RequestUnlock String String
    | SignOutBE (Maybe String)
    | GetHomePage String
    | FetchDocumentById String (Maybe String)
    | GetPublicDocuments (Maybe String)
    | SaveDocument Evergreen.V269.Document.Document
    | GetDocumentByAuthorId String
    | GetDocumentByPublicId String
    | GetDocumentById String
    | CreateDocument (Maybe Evergreen.V269.User.User) Evergreen.V269.Document.Document
    | ApplySpecial Evergreen.V269.User.User String
    | SearchForDocuments (Maybe String) String
    | DeleteDocumentBE Evergreen.V269.Document.Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type BackendMsg
    = ClientConnected Lamdera.SessionId Lamdera.ClientId
    | ClientDisconnected Lamdera.SessionId Lamdera.ClientId
    | GotAtomsphericRandomNumber (Result Http.Error String)
    | DelaySendingDocument Lamdera.ClientId Evergreen.V269.Document.Document
    | Tick Time.Posix


type ToFrontend
    = SendBackupData String
    | GotUserList (List ( Evergreen.V269.User.User, Int ))
    | GotConnectionList (List String)
    | GotShareDocumentList (List ( String, SharedDocument ))
    | UserMessageReceived Evergreen.V269.UserMessage.UserMessage
    | UserSignedUp Evergreen.V269.User.User
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
    | SendDocument SystemDocPermissions Evergreen.V269.Document.Document
    | SendDocuments (List Evergreen.V269.Document.Document)
    | SendMessage Message
    | StatusReport (List String)
    | SetShowEditor Bool
    | GotPublicDocuments (List Evergreen.V269.Document.Document)
