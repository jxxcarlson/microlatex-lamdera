module Types exposing
    ( AbstractDict
    , AbstractDictOLD
    , ActiveDocList(..)
    , AppMode(..)
    , AuthorDict
    , BackendModel
    , BackendMsg(..)
    , BackupOLD
    , ChatDict
    , ChatGroup
    , ChatMsg(..)
    , ConnectionData
    , ConnectionDict
    , DocId
    , DocLoaded(..)
    , DocumentDeleteState(..)
    , DocumentDict
    , DocumentHandling(..)
    , DocumentHardDeleteState(..)
    , DocumentLink
    , DocumentList(..)
    , FailureAction(..)
    , FrontendModel
    , FrontendMsg(..)
    , GroupName
    , ManualType(..)
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
    , SharedDocument
    , SharedDocumentDict
    , SidebarExtrasState(..)
    , SidebarTagsState(..)
    , SignupState(..)
    , SortMode(..)
    , TagItem
    , TagSelection(..)
    , ToBackend(..)
    , ToFrontend(..)
    , ToggleChatGroupDisplay(..)
    , UMButtons(..)
    , UserId
    , UserMessage
    , Username
    , UsersDocumentsDict
    )

import Abstract exposing (Abstract, AbstractOLD)
import Authentication exposing (AuthenticationDict)
import Browser exposing (UrlRequest)
import Chat.Message
import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OT as OT
import CollaborativeEditing.OTCommand as OTCommand
import Compiler.DifferentialParser
import Debounce exposing (Debounce)
import Deque exposing (Deque)
import Dict exposing (Dict)
import Document exposing (Document)
import Effect.Browser.Dom
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time
import Keyboard
import Parser.Block exposing (ExpressionBlock)
import Parser.Language exposing (Language)
import Random
import Render.Msg
import Url exposing (Url)
import User exposing (User)



-- FRONT END MODEL


type alias FrontendModel =
    { --SYSTEM
      key : Effect.Browser.Navigation.Key
    , url : Url
    , messages : List Message
    , currentTime : Effect.Time.Posix
    , zone : Effect.Time.Zone
    , timeSignedIn : Effect.Time.Posix
    , lastInteractionTime : Effect.Time.Posix
    , timer : Int
    , showSignInTimer : Bool

    -- ADMIN
    , statusReport : List String
    , inputSpecial : String
    , userList : List ( String, Int )
    , connectedUsers : List String
    , sharedDocumentList : List ( String, Bool, SharedDocument )

    -- USER
    , userMessage : Maybe UserMessage
    , currentUser : Maybe User

    -- INPUT
    , inputCommand : String
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputTitle : String
    , inputLanguage : Language
    , inputSearchTagsKey : String
    , inputReaders : String
    , inputEditors : String

    -- TAGS
    , tagDict : Dict String (List TagItem)
    , publicTagDict : Dict String (List TagItem)
    , documentList : DocumentList

    -- UI
    , appMode : AppMode
    , windowWidth : Int
    , windowHeight : Int
    , popupStatus : PopupStatus
    , authorId : String
    , phoneMode : PhoneMode
    , pressedKeys : List Keyboard.Key
    , maximizedIndex : MaximizedIndex
    , sidebarExtrasState : SidebarExtrasState
    , sidebarTagsState : SidebarTagsState
    , tagSelection : TagSelection
    , signupState : SignupState
    , popupState : PopupState

    -- CHAT
    , chatDisplay : ToggleChatGroupDisplay
    , inputGroupMembers : String
    , inputGroupName : String
    , inputGroupAssistant : String
    , chatMessages : List ChatMsg
    , chatMessageFieldContent : String
    , chatVisible : Bool
    , inputGroup : String
    , currentChatGroup : Maybe ChatGroup

    -- SYNC
    , foundIds : List String
    , foundIdIndex : Int
    , selectedId : String
    , selectedSlug : Maybe String
    , syncRequestIndex : Int
    , linenumber : Int

    -- COLLABORATIVE EDITING
    , editCommand : { counter : Int, command : Maybe OTCommand.Command }
    , editorEvent : { counter : Int, cursor : Int, event : Maybe NetworkModel.EditEvent }
    , eventQueue : Deque NetworkModel.EditEvent
    , collaborativeEditing : Bool
    , editorCursor : Int
    , myCursorPosition : { x : Int, y : Int, p : Int }
    , networkModel : NetworkModel.NetworkModel
    , oTDocument : OT.Document

    -- SHARED EDITING
    , activeEditor : Maybe { name : String, activeAt : Effect.Time.Posix }

    -- FLAGS
    , documentDirty : Bool
    , seeBackups : Bool
    , showEditor : Bool
    , showDocTools : Bool
    , showPublicUrl : Bool
    , doSync : Bool

    -- DOCUMENT
    -- DATA STRUCTURES
    , activeDocList : ActiveDocList
    , includedContent : Dict String String
    , currentDocument : Maybe Document
    , currentManual : Maybe Document
    , currentMasterDocument : Maybe Document
    , documents : List Document
    , pinnedDocuments : List Document.DocumentInfo
    , publicDocuments : List Document
    , initialText : String
    , sourceText : String
    , editRecord : Compiler.DifferentialParser.EditRecord
    , tableOfContents : List ExpressionBlock

    -- Unclassified
    , title : String
    , lineNumber : Int
    , permissions : DocumentHandling
    , debounce : Debounce String

    -- SEARCH
    , publicDocumentSearchKey : String
    , documentsCreatedCounter : Int
    , searchCount : Int
    , searchSourceText : String
    , inputSearchKey : String
    , actualSearchKey : String

    -- STATE
    , docLoaded : DocLoaded
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , deleteDocumentState : DocumentDeleteState
    , hardDeleteDocumentState : DocumentHardDeleteState
    , sortMode : SortMode
    , language : Language
    }


type alias TagItem =
    { id : String, title : String }



-- BACKEND MODEL


type alias BackendModel =
    { message : String
    , currentTime : Effect.Time.Posix

    -- RANDOM
    , randomSeed : Random.Seed
    , uuidCount : Int
    , randomAtmosphericInt : Maybe Int

    -- CHAT
    , chatDict : ChatDict
    , chatGroupDict : ChatGroupDict

    -- USER
    , authenticationDict : AuthenticationDict

    -- DATA
    , documentDict : DocumentDict
    , slugDict : SlugDict
    , sharedDocumentDict : SharedDocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , connectionDict : ConnectionDict

    -- DOCUMENT
    , editEvents : Deque NetworkModel.EditEvent
    , documents : List Document
    , publicDocuments : List Document
    }



-- FRONTENDMSG


type FrontendMsg
    = FENoOp
    | UrlClicked Browser.UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | FETick Effect.Time.Posix
    | AdjustTimeZone Effect.Time.Zone
    | GotTime Effect.Time.Posix
    | Render Render.Msg.MarkupMsg
      -- UI
    | ToggleCheatsheet
    | ToggleManuals ManualType
    | OpenSharedDocumentList
    | SetAppMode AppMode
    | GotNewWindowDimensions Int Int
    | GotViewport Effect.Browser.Dom.Viewport
    | SetViewPortForElement (Result Effect.Browser.Dom.Error ( Effect.Browser.Dom.Element, Effect.Browser.Dom.Viewport ))
    | ChangePopupStatus PopupStatus
    | CloseEditor
    | OpenEditor
    | Home
    | KeyMsg Keyboard.Msg
      -- ADMIN
    | InputSpecial String
    | RunSpecial
    | GoGetUserList
    | ClearConnectionDict
      -- USER
    | SendUserMessage UserMessage
    | SignIn
    | SetSignupState SignupState
    | DoSignUp
    | SignOut
    | InputCommand String
    | RunNetworkModelCommand
    | InputUsername String
    | InputPassword String
    | ClearPassword
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
    | TogglePublicUrl
    | ToggleDocTools
    | ToggleActiveDocList
    | CloseCollectionIndex
    | ToggleIndexSize
    | ToggleExtrasSidebar
    | ToggleTagsSidebar
    | ChangePopup PopupState
      -- SHARE
    | DismissUserMessage
    | Narrow String Document
    | ShareDocument
    | DoShare
      -- CHAT (FrontendMsg)
    | AskToClearChatHistory
    | ScrollChatToBottom
    | SetChatGroup
    | GetChatHistory
    | CreateChatGroup
    | SetChatDisplay ToggleChatGroupDisplay
    | InputGroupMembers String
    | InputGroupName String
    | InputGroupAssistant String
    | ToggleChat
    | MessageFieldChanged String
    | MessageSubmitted
    | InputChoseGroup String
      -- DOCUMENT
    | ToggleCollaborativeEditing
    | SetDocumentStatus Document.DocStatus
    | ChangeLanguage
    | MakeBackup
    | ToggleBackupVisibility
    | SetDocumentCurrent Document
    | SetDocumentCurrentViaId Document.DocumentId
    | GetPinnedDocuments
    | SetLanguage Bool Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent DocumentHandling Document
    | ShowTOCInPhone
    | InputSearchSource String
    | InputText { position : Int, source : String }
    | InputCursor { position : Int, source : String }
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
    | SetDocumentAsCurrent DocumentHandling Document
    | SetPublic Document Bool
    | AskForDocumentById DocumentHandling String
    | AskForDocumentByAuthorId
    | SoftDeleteDocument
    | HardDeleteDocument
    | SetDeleteDocumentState DocumentDeleteState
    | SetHardDeleteDocumentState DocumentHardDeleteState
    | SetSortMode SortMode
    | SelectList DocumentList
    | GetUserTags
    | GetPublicTags
      -- Export
    | ExportToMarkdown
    | ExportToLaTeX
    | ExportToRawLaTeX
    | ExportTo Language
    | Export
      -- PDF
    | PrintToPDF
    | GotPdfLink (Result Effect.Http.Error String)
    | ChangePrintingState PrintingState
    | FinallyDoCleanPrintArtefacts String
      ---
    | Help String


type ManualType
    = TManual
    | TGuide



-- BACKENDMSG


type BackendMsg
    = ClientConnected SessionId ClientId
    | ClientDisconnected SessionId ClientId
    | GotAtomsphericRandomNumber (Result Effect.Http.Error String)
    | DelaySendingDocument Effect.Lamdera.ClientId Document
    | Tick Effect.Time.Posix



-- TOBACKEND (MSG)


type ToBackend
    = --ADMIN
      RunTask
    | GetStatus
    | GetUserList
    | GetUsersWithOnlineStatus
    | GetSharedDocuments String
    | ClearConnectionDictBE
      -- USER
    | DeliverUserMessage UserMessage -- from, to, subject, contents
    | SignInBE String String
    | SignUpBE String Language String String String
    | UpdateUserWith User
      -- CHAT (ToBackend)
    | ClearChatHistory String
    | SendChatHistory String
    | InsertChatGroup ChatGroup
    | GetChatGroup String
    | ChatMsgSubmitted Chat.Message.ChatMessage
      -- SHARE
    | ClearEditEvents UserId
    | Narrowcast Username UserId Document -- First arg is the sender's username.  Send the document
    | NarrowcastExceptToSender Username UserId Document -- First arg is the sender's username.  Send the document
    | UpdateSharedDocumentDict User Document
    | AddEditor User Document
    | RemoveEditor User Document
      -- to all users in the document's share list, plus the author, minus the sender who have active connections
      -- DOCUMENT
    | InitializeNetworkModelsWithDocument Document
    | ResetNetworkModelForDocument Document
    | PushEditorEvent NetworkModel.EditEvent
    | GetIncludedFiles Document (List String)
    | InsertDocument User Document
    | GetCheatSheetDocument
    | RequestRefresh String
    | SignOutBE (Maybe String)
    | GetHomePage String
    | FetchDocumentById DocumentHandling Document.DocumentId
    | FindDocumentByAuthorAndKey DocumentHandling Username String
    | GetPublicDocuments SortMode (Maybe String)
    | SaveDocument (Maybe User) Document
    | SearchForDocumentsWithAuthorAndKey String
    | SearchForDocuments DocumentHandling (Maybe String) String
    | GetDocumentByPublicId String
    | GetDocumentById DocumentHandling String
    | CreateDocument (Maybe User) Document
    | ApplySpecial User String
    | HardDeleteDocumentBE Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE



-- TOFRONTEND (MSG)


type ToFrontend
    = -- ADMIN
      SendBackupData String
    | GotUsersWithOnlineStatus (List ( String, Int ))
    | GotConnectionList (List String)
    | GotShareDocumentList (List ( String, Bool, SharedDocument ))
      -- USER
    | UserMessageReceived UserMessage
    | UndeliverableMessage UserMessage
    | UserSignedUp User
      -- CHAT
    | GotChatHistory (List ChatMsg)
    | GotChatGroup (Maybe ChatGroup)
    | ChatMessageReceived ChatMsg
      -- DOCUMENT
    | ResetNetworkModel NetworkModel.NetworkModel Document
    | InitializeNetworkModel NetworkModel.NetworkModel
    | ProcessEvent NetworkModel.EditEvent
    | GotIncludedData Document (List ( String, String ))
    | AcceptUserTags (Dict String (List TagItem))
    | AcceptPublicTags (Dict String (List TagItem))
    | ReceivedDocument DocumentHandling Document
    | ReceivedNewDocument DocumentHandling Document
    | ReceivedDocuments DocumentHandling (List Document)
    | ReceivedPublicDocuments (List Document)
    | MessageReceived Message
    | StatusReport (List String)
    | SetShowEditor Bool



-- CHAT


type alias ChatDict =
    Dict GroupName (List Chat.Message.ChatMessage)


type alias ChatGroupDict =
    Dict GroupName ChatGroup


type alias ChatGroup =
    { name : String
    , members : List Username
    , owner : Username
    , assistant : Maybe Username
    }


type ChatMsg
    = JoinedChat ClientId Username
    | LeftChat ClientId Username
    | ChatMsg ClientId Chat.Message.ChatMessage


type alias GroupName =
    String


type ToggleChatGroupDisplay
    = TCGDisplay
    | TCGShowInputForm



-- MESSAGE


type alias Message =
    { txt : String, status : MessageStatus }


type MessageStatus
    = MSWhite
    | MSYellow
    | MSGreen
    | MSRed



-- POPUPS


type PopupState
    = NoPopup
    | LanguageMenuPopup
    | NewDocumentPopup
    | UserMessagePopup
    | GuidesPopup
    | ManualsPopup
    | SharePopup
    | NetworkMonitorPopup


type TagSelection
    = TagPublic
    | TagUser


type MaximizedIndex
    = MMyDocs
    | MPublicDocs


type ActiveDocList
    = PublicDocsList
    | PrivateDocsList
    | Both



-- DOC Types


type DocumentDeleteState
    = WaitingForDeleteAction
    | CanDelete


type DocumentHardDeleteState
    = WaitingForHardDeleteAction
    | CanHardDelete


type SortMode
    = SortAlphabetically
    | SortByMostRecent


type DocLoaded
    = NotLoaded


type DocumentList
    = WorkingList
    | StandardList
    | SharedDocumentList
    | PinnedDocs


type PrintingState
    = PrintWaiting
    | PrintProcessing
    | PrintReady


type DocumentHandling
    = StandardHandling
    | HandleSharedDocument Username
    | PinnedDocumentList
    | DelayedHandling
    | HandleAsManual



-- APP TYPES


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



-- USERMESSAGE


type alias UserMessage =
    { from : String
    , to : String
    , subject : String
    , content : String
    , show : List UMButtons
    , info : String -- e.g., "docId:abc1234uji"
    , action : FrontendMsg
    , actionOnFailureToDeliver : FailureAction
    }


type FailureAction
    = FANoOp
    | FAUnlockCurrentDocument


type UMButtons
    = UMOk
    | UMNotYet
    | UMDismiss
    | UMUnlock


type SidebarExtrasState
    = SidebarExtrasIn
    | SidebarExtrasOut


type SidebarTagsState
    = SidebarTagsIn
    | SidebarTagsOut


type SearchTerm
    = Query String


type SignupState
    = ShowSignUpForm
    | HideSignUpForm



-- ALIASES


{-| keys are usernames
values are lists of ConnectionData because a user could have various active sessions
-}
type alias ConnectionDict =
    Dict String (List ConnectionData)


type alias ConnectionData =
    { session : SessionId, client : ClientId }


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


{-| slug -> docId
-}
type alias SlugDict =
    Dict String String


{-| User id -> List docId
-}
type alias UsersDocumentsDict =
    Dict UserId (List DocId)


type alias SharedDocument =
    { title : String
    , id : String
    , author : Maybe String
    , share : Document.SharedWith
    , currentEditors : List Document.EditorData -- users online currently editing this document.
    }


{-| key = docId
-}
type alias SharedDocumentDict =
    Dict DocId SharedDocument



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


type alias Username =
    String


type alias BackupOLD =
    { message : String
    , currentTime : Effect.Time.Posix

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
