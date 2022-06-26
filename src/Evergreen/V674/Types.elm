module Evergreen.V674.Types exposing (..)

import Browser
import Deque
import Dict
import Effect.Browser.Dom
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V674.Abstract
import Evergreen.V674.Authentication
import Evergreen.V674.Chat.Message
import Evergreen.V674.CollaborativeEditing.NetworkModel
import Evergreen.V674.CollaborativeEditing.OT
import Evergreen.V674.CollaborativeEditing.OTCommand
import Evergreen.V674.Compiler.DifferentialParser
import Evergreen.V674.Debounce
import Evergreen.V674.Document
import Evergreen.V674.Keyboard
import Evergreen.V674.Parser.Block
import Evergreen.V674.Parser.Language
import Evergreen.V674.Render.Msg
import Evergreen.V674.User
import Random
import Url


type MessageStatus
    = MSWhite
    | MSYellow
    | MSGreen
    | MSRed


type alias Message =
    { txt : String
    , status : MessageStatus
    }


type alias SharedDocument =
    { title : String
    , id : String
    , author : Maybe String
    , share : Evergreen.V674.Document.SharedWith
    , currentEditors : List Evergreen.V674.Document.EditorData
    }


type UMButtons
    = UMOk
    | UMNotYet
    | UMDismiss
    | UMUnlock


type ManualType
    = TManual
    | TGuide


type AppMode
    = UserMode
    | AdminMode


type PopupStatus
    = PopupClosed


type FailureAction
    = FANoOp
    | FAUnlockCurrentDocument


type alias UserMessage =
    { from : String
    , to : String
    , subject : String
    , content : String
    , show : List UMButtons
    , info : String
    , action : FrontendMsg
    , actionOnFailureToDeliver : FailureAction
    }


type SignupState
    = ShowSignUpForm
    | HideSignUpForm


type PopupState
    = NoPopup
    | LanguageMenuPopup
    | NewDocumentPopup
    | UserMessagePopup
    | GuidesPopup
    | ManualsPopup
    | SharePopup
    | NetworkMonitorPopup


type ToggleChatGroupDisplay
    = TCGDisplay
    | TCGShowInputForm


type alias Username =
    String


type DocumentHandling
    = StandardHandling
    | HandleSharedDocument Username
    | PinnedDocumentList
    | DelayedHandling
    | HandleAsManual


type DocumentDeleteState
    = WaitingForDeleteAction
    | CanDelete


type DocumentHardDeleteState
    = WaitingForHardDeleteAction
    | CanHardDelete


type SortMode
    = SortAlphabetically
    | SortByMostRecent


type DocumentList
    = WorkingList
    | StandardList
    | SharedDocumentList
    | PinnedDocs


type PrintingState
    = PrintWaiting
    | PrintProcessing
    | PrintReady


type FrontendMsg
    = FENoOp
    | UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | FETick Effect.Time.Posix
    | AdjustTimeZone Effect.Time.Zone
    | GotTime Effect.Time.Posix
    | Render Evergreen.V674.Render.Msg.MarkupMsg
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
    | KeyMsg Evergreen.V674.Keyboard.Msg
    | InputSpecial String
    | RunSpecial
    | GoGetUserList
    | ClearConnectionDict
    | SendUserMessage UserMessage
    | SignIn
    | SetSignupState SignupState
    | SignUp
    | SignOut
    | InputCommand String
    | RunNetworkModelCommand
    | InputUsername String
    | InputSignupUsername String
    | InputPassword String
    | ClearPassword
    | InputPasswordAgain String
    | InputRealname String
    | InputEmail String
    | SetUserLanguage Evergreen.V674.Parser.Language.Language
    | SelectedText String
    | SyncLR
    | StartSync
    | NextSync
    | SendSyncLR
    | GetSelection String
    | TogglePublicUrl
    | ToggleDocTools
    | ToggleActiveDocList
    | CloseCollectionIndex
    | ToggleIndexSize
    | ToggleExtrasSidebar
    | ToggleTagsSidebar
    | ChangePopup PopupState
    | DismissUserMessage
    | Narrow String Evergreen.V674.Document.Document
    | ShareDocument
    | DoShare
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
    | ToggleCollaborativeEditing
    | ApplyEdits
    | SetDocumentStatus Evergreen.V674.Document.DocStatus
    | ChangeLanguage
    | MakeBackup
    | ToggleBackupVisibility
    | SetDocumentCurrent Evergreen.V674.Document.Document
    | SetDocumentCurrentViaId Evergreen.V674.Document.DocumentId
    | GetPinnedDocuments
    | SetLanguage Bool Evergreen.V674.Parser.Language.Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent DocumentHandling Evergreen.V674.Document.Document
    | ShowTOCInPhone
    | InputSearchSource String
    | InputText
        { position : Int
        , source : String
        }
    | InputCursor
        { position : Int
        , source : String
        }
    | InputTitle String
    | InputReaders String
    | InputEditors String
    | DebounceMsg Evergreen.V674.Debounce.Msg
    | Saved String
    | InputSearchKey String
    | InputSearchTagsKey String
    | Search
    | SearchText
    | InputAuthorId String
    | NewDocument
    | SetDocumentAsCurrent DocumentHandling Evergreen.V674.Document.Document
    | SetPublic Evergreen.V674.Document.Document Bool
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
    | ExportToMarkdown
    | ExportToLaTeX
    | ExportToRawLaTeX
    | ExportTo Evergreen.V674.Parser.Language.Language
    | Export
    | PrintToPDF
    | GotPdfLink (Result Effect.Http.Error String)
    | ChangePrintingState PrintingState
    | FinallyDoCleanPrintArtefacts String
    | Help String


type alias TagItem =
    { id : String
    , title : String
    }


type PhoneMode
    = PMShowDocument
    | PMShowDocumentList


type MaximizedIndex
    = MMyDocs
    | MPublicDocs


type SidebarExtrasState
    = SidebarExtrasIn
    | SidebarExtrasOut


type SidebarTagsState
    = SidebarTagsIn
    | SidebarTagsOut


type TagSelection
    = TagPublic
    | TagUser


type ChatMsg
    = JoinedChat Effect.Lamdera.ClientId Username
    | LeftChat Effect.Lamdera.ClientId Username
    | ChatMsg Effect.Lamdera.ClientId Evergreen.V674.Chat.Message.ChatMessage


type alias ChatGroup =
    { name : String
    , members : List Username
    , owner : Username
    , assistant : Maybe Username
    }


type ActiveDocList
    = PublicDocsList
    | PrivateDocsList
    | Both


type DocLoaded
    = NotLoaded


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , url : Url.Url
    , messages : List Message
    , currentTime : Effect.Time.Posix
    , zone : Effect.Time.Zone
    , timeSignedIn : Effect.Time.Posix
    , lastInteractionTime : Effect.Time.Posix
    , timer : Int
    , showSignInTimer : Bool
    , statusReport : List String
    , inputSpecial : String
    , userList : List ( String, Int )
    , connectedUsers : List String
    , sharedDocumentList : List ( String, Bool, SharedDocument )
    , userMessage : Maybe UserMessage
    , currentUser : Maybe Evergreen.V674.User.User
    , clientIds : List Effect.Lamdera.ClientId
    , inputCommand : String
    , inputUsername : String
    , inputSignupUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputTitle : String
    , inputLanguage : Evergreen.V674.Parser.Language.Language
    , inputSearchTagsKey : String
    , inputReaders : String
    , inputEditors : String
    , tagDict : Dict.Dict String (List TagItem)
    , publicTagDict : Dict.Dict String (List TagItem)
    , documentList : DocumentList
    , appMode : AppMode
    , windowWidth : Int
    , windowHeight : Int
    , popupStatus : PopupStatus
    , authorId : String
    , phoneMode : PhoneMode
    , pressedKeys : List Evergreen.V674.Keyboard.Key
    , maximizedIndex : MaximizedIndex
    , sidebarExtrasState : SidebarExtrasState
    , sidebarTagsState : SidebarTagsState
    , tagSelection : TagSelection
    , signupState : SignupState
    , popupState : PopupState
    , chatDisplay : ToggleChatGroupDisplay
    , inputGroupMembers : String
    , inputGroupName : String
    , inputGroupAssistant : String
    , chatMessages : List ChatMsg
    , chatMessageFieldContent : String
    , chatVisible : Bool
    , inputGroup : String
    , currentChatGroup : Maybe ChatGroup
    , foundIds : List String
    , foundIdIndex : Int
    , selectedId : String
    , selectedSlug : Maybe String
    , syncRequestIndex : Int
    , linenumber : Int
    , editCommand :
        { counter : Int
        , command : Evergreen.V674.CollaborativeEditing.OTCommand.Command
        }
    , editorEvent :
        { counter : Int
        , cursor : Int
        , event : Maybe Evergreen.V674.CollaborativeEditing.NetworkModel.EditEvent
        }
    , eventQueue : Deque.Deque Evergreen.V674.CollaborativeEditing.NetworkModel.EditEvent
    , collaborativeEditing : Bool
    , editorCursor : Int
    , myCursorPosition :
        { x : Int
        , y : Int
        , p : Int
        }
    , networkModel : Evergreen.V674.CollaborativeEditing.NetworkModel.NetworkModel
    , oTDocument : Evergreen.V674.CollaborativeEditing.OT.Document
    , activeEditor :
        Maybe
            { name : String
            , activeAt : Effect.Time.Posix
            }
    , documentDirty : Bool
    , seeBackups : Bool
    , showEditor : Bool
    , showDocTools : Bool
    , showPublicUrl : Bool
    , doSync : Bool
    , activeDocList : ActiveDocList
    , includedContent : Dict.Dict String String
    , currentDocument : Maybe Evergreen.V674.Document.Document
    , currentManual : Maybe Evergreen.V674.Document.Document
    , currentMasterDocument : Maybe Evergreen.V674.Document.Document
    , documents : List Evergreen.V674.Document.Document
    , pinnedDocuments : List Evergreen.V674.Document.DocumentInfo
    , publicDocuments : List Evergreen.V674.Document.Document
    , initialText : String
    , sourceText : String
    , editRecord : Evergreen.V674.Compiler.DifferentialParser.EditRecord
    , tableOfContents : List Evergreen.V674.Parser.Block.ExpressionBlock
    , title : String
    , lineNumber : Int
    , permissions : DocumentHandling
    , debounce : Evergreen.V674.Debounce.Debounce String
    , publicDocumentSearchKey : String
    , documentsCreatedCounter : Int
    , searchCount : Int
    , searchSourceText : String
    , inputSearchKey : String
    , actualSearchKey : String
    , docLoaded : DocLoaded
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , deleteDocumentState : DocumentDeleteState
    , hardDeleteDocumentState : DocumentHardDeleteState
    , sortMode : SortMode
    , language : Evergreen.V674.Parser.Language.Language
    }


type alias GroupName =
    String


type alias ChatDict =
    Dict.Dict GroupName (List Evergreen.V674.Chat.Message.ChatMessage)


type alias ChatGroupDict =
    Dict.Dict GroupName ChatGroup


type alias DocumentDict =
    Dict.Dict String Evergreen.V674.Document.Document


type alias SlugDict =
    Dict.Dict String String


type alias DocId =
    String


type alias SharedDocumentDict =
    Dict.Dict DocId SharedDocument


type alias AuthorDict =
    Dict.Dict String String


type alias PublicIdDict =
    Dict.Dict String String


type alias AbstractDict =
    Dict.Dict String Evergreen.V674.Abstract.Abstract


type alias UserId =
    String


type alias UsersDocumentsDict =
    Dict.Dict UserId (List DocId)


type alias ConnectionData =
    { session : Effect.Lamdera.SessionId
    , client : Effect.Lamdera.ClientId
    }


type alias ConnectionDict =
    Dict.Dict String (List ConnectionData)


type alias BackendModel =
    { message : String
    , currentTime : Effect.Time.Posix
    , randomSeed : Random.Seed
    , uuidCount : Int
    , randomAtmosphericInt : Maybe Int
    , chatDict : ChatDict
    , chatGroupDict : ChatGroupDict
    , authenticationDict : Evergreen.V674.Authentication.AuthenticationDict
    , documentDict : DocumentDict
    , slugDict : SlugDict
    , sharedDocumentDict : SharedDocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , connectionDict : ConnectionDict
    , editEvents : Deque.Deque Evergreen.V674.CollaborativeEditing.NetworkModel.EditEvent
    , documents : List Evergreen.V674.Document.Document
    , publicDocuments : List Evergreen.V674.Document.Document
    }


type ToBackend
    = RunTask
    | GetStatus
    | GetUserList
    | GetUsersWithOnlineStatus
    | GetSharedDocuments String
    | ClearConnectionDictBE
    | DeliverUserMessage UserMessage
    | SignInBE String String
    | SignUpBE String Evergreen.V674.Parser.Language.Language String String String
    | UpdateUserWith Evergreen.V674.User.User
    | ClearChatHistory String
    | SendChatHistory String
    | InsertChatGroup ChatGroup
    | GetChatGroup String
    | ChatMsgSubmitted Evergreen.V674.Chat.Message.ChatMessage
    | ClearEditEvents UserId
    | Narrowcast Username UserId Evergreen.V674.Document.Document
    | NarrowcastExceptToSender Username UserId Evergreen.V674.Document.Document
    | UpdateSharedDocumentDict Evergreen.V674.User.User Evergreen.V674.Document.Document
    | AddEditor Evergreen.V674.User.User Evergreen.V674.Document.Document
    | RemoveEditor Evergreen.V674.User.User Evergreen.V674.Document.Document
    | InitializeNetworkModelsWithDocument Evergreen.V674.Document.Document
    | ResetNetworkModelForDocument Evergreen.V674.Document.Document
    | PushEditorEvent Evergreen.V674.CollaborativeEditing.NetworkModel.EditEvent
    | GetIncludedFiles Evergreen.V674.Document.Document (List String)
    | InsertDocument Evergreen.V674.User.User Evergreen.V674.Document.Document
    | GetCheatSheetDocument
    | RequestRefresh String
    | SignOutBE (Maybe String)
    | GetHomePage String
    | FetchDocumentById DocumentHandling Evergreen.V674.Document.DocumentId
    | FindDocumentByAuthorAndKey DocumentHandling Username String
    | GetPublicDocuments SortMode (Maybe String)
    | SaveDocument (Maybe Evergreen.V674.User.User) Evergreen.V674.Document.Document
    | SearchForDocumentsWithAuthorAndKey String
    | SearchForDocuments DocumentHandling (Maybe String) String
    | GetDocumentByPublicId String
    | GetDocumentById DocumentHandling String
    | CreateDocument (Maybe Evergreen.V674.User.User) Evergreen.V674.Document.Document
    | ApplySpecial Evergreen.V674.User.User String
    | HardDeleteDocumentBE Evergreen.V674.Document.Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type BackendMsg
    = ClientConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | ClientDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | GotAtomsphericRandomNumber (Result Effect.Http.Error String)
    | DelaySendingDocument Effect.Lamdera.ClientId Evergreen.V674.Document.Document
    | Tick Effect.Time.Posix


type ToFrontend
    = SendBackupData String
    | GotUsersWithOnlineStatus (List ( String, Int ))
    | GotConnectionList (List String)
    | GotShareDocumentList (List ( String, Bool, SharedDocument ))
    | UserMessageReceived UserMessage
    | UndeliverableMessage UserMessage
    | UserSignedUp Evergreen.V674.User.User Effect.Lamdera.ClientId
    | GotChatHistory (List ChatMsg)
    | GotChatGroup (Maybe ChatGroup)
    | ChatMessageReceived ChatMsg
    | ResetNetworkModel Evergreen.V674.CollaborativeEditing.NetworkModel.NetworkModel Evergreen.V674.Document.Document
    | InitializeNetworkModel Evergreen.V674.CollaborativeEditing.NetworkModel.NetworkModel
    | ProcessEvent Evergreen.V674.CollaborativeEditing.NetworkModel.EditEvent
    | GotIncludedData Evergreen.V674.Document.Document (List ( String, String ))
    | AcceptUserTags (Dict.Dict String (List TagItem))
    | AcceptPublicTags (Dict.Dict String (List TagItem))
    | ReceivedDocument DocumentHandling Evergreen.V674.Document.Document
    | ReceivedNewDocument DocumentHandling Evergreen.V674.Document.Document
    | ReceivedDocuments DocumentHandling (List Evergreen.V674.Document.Document)
    | ReceivedPublicDocuments (List Evergreen.V674.Document.Document)
    | MessageReceived Message
    | StatusReport (List String)
    | SetShowEditor Bool
