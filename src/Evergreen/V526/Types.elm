module Evergreen.V526.Types exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation
import Debounce
import Deque
import Dict
import Evergreen.V526.Abstract
import Evergreen.V526.Authentication
import Evergreen.V526.Chat.Message
import Evergreen.V526.CollaborativeEditing.NetworkModel
import Evergreen.V526.CollaborativeEditing.OTCommand
import Evergreen.V526.Compiler.DifferentialParser
import Evergreen.V526.Document
import Evergreen.V526.Parser.Block
import Evergreen.V526.Parser.Language
import Evergreen.V526.Render.Msg
import Evergreen.V526.User
import Http
import Keyboard
import Lamdera
import Random
import Time
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
    , share : Evergreen.V526.Document.SharedWith
    , currentEditors :
        List
            { username : String
            , userId : String
            , clientId : Lamdera.ClientId
            }
    }


type UMButtons
    = UMOk
    | UMNotYet
    | UMDismiss
    | UMUnlock


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
    | CheatSheetPopup
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
    | HandleAsCheatSheet


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
    | FETick Time.Posix
    | AdjustTimeZone Time.Zone
    | GotTime Time.Posix
    | Render Evergreen.V526.Render.Msg.MarkupMsg
    | ToggleCheatsheet
    | ToggleManuals
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
    | SendUserMessage UserMessage
    | SignIn
    | SetSignupState SignupState
    | DoSignUp
    | SignOut
    | InputCommand String
    | RunCommand
    | InputUsername String
    | InputPassword String
    | InputPasswordAgain String
    | InputRealname String
    | InputEmail String
    | SetUserLanguage Evergreen.V526.Parser.Language.Language
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
    | Narrow String Evergreen.V526.Document.Document
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
    | SetDocumentStatus Evergreen.V526.Document.DocStatus
    | ChangeLanguage
    | MakeBackup
    | ToggleBackupVisibility
    | SetDocumentCurrent Evergreen.V526.Document.Document
    | SetDocumentCurrentViaId Evergreen.V526.Document.DocumentId
    | GetPinnedDocuments
    | SetLanguage Bool Evergreen.V526.Parser.Language.Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent DocumentHandling Evergreen.V526.Document.Document
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
    | DebounceMsg Debounce.Msg
    | Saved String
    | InputSearchKey String
    | InputSearchTagsKey String
    | Search
    | SearchText
    | InputAuthorId String
    | NewDocument
    | SetDocumentAsCurrent DocumentHandling Evergreen.V526.Document.Document
    | SetPublic Evergreen.V526.Document.Document Bool
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
    | ExportTo Evergreen.V526.Parser.Language.Language
    | Export
    | PrintToPDF
    | GotPdfLink (Result Http.Error String)
    | ChangePrintingState PrintingState
    | FinallyDoCleanPrintArtefacts String
    | Help String


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
    = JoinedChat Lamdera.ClientId Username
    | LeftChat Lamdera.ClientId Username
    | ChatMsg Lamdera.ClientId Evergreen.V526.Chat.Message.ChatMessage


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
    { key : Browser.Navigation.Key
    , url : Url.Url
    , messages : List Message
    , currentTime : Time.Posix
    , zone : Time.Zone
    , timeSignedIn : Time.Posix
    , lastInteractionTime : Time.Posix
    , statusReport : List String
    , inputSpecial : String
    , userList : List ( String, Int )
    , connectedUsers : List String
    , sharedDocumentList : List ( String, Bool, SharedDocument )
    , userMessage : Maybe UserMessage
    , currentUser : Maybe Evergreen.V526.User.User
    , inputCommand : String
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputTitle : String
    , inputLanguage : Evergreen.V526.Parser.Language.Language
    , inputSearchTagsKey : String
    , inputReaders : String
    , inputEditors : String
    , tagDict :
        Dict.Dict
            String
            (List
                { id : String
                , title : String
                }
            )
    , publicTagDict :
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
    , authorId : String
    , phoneMode : PhoneMode
    , pressedKeys : List Keyboard.Key
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
    , syncRequestIndex : Int
    , linenumber : Int
    , editCommand :
        { counter : Int
        , command : Maybe Evergreen.V526.CollaborativeEditing.OTCommand.Command
        }
    , editorEvent :
        { counter : Int
        , cursor : Int
        , event : Maybe Evergreen.V526.CollaborativeEditing.NetworkModel.EditEvent
        }
    , eventQueue : Deque.Deque Evergreen.V526.CollaborativeEditing.NetworkModel.EditEvent
    , collaborativeEditing : Bool
    , editorCursor : Int
    , myCursorPosition :
        { x : Int
        , y : Int
        , p : Int
        }
    , networkModel : Evergreen.V526.CollaborativeEditing.NetworkModel.NetworkModel
    , activeEditor :
        Maybe
            { name : String
            , activeAt : Time.Posix
            }
    , documentDirty : Bool
    , seeBackups : Bool
    , showEditor : Bool
    , showDocTools : Bool
    , showPublicUrl : Bool
    , doSync : Bool
    , activeDocList : ActiveDocList
    , includedContent : Dict.Dict String String
    , currentDocument : Maybe Evergreen.V526.Document.Document
    , currentCheatsheet : Maybe Evergreen.V526.Document.Document
    , currentMasterDocument : Maybe Evergreen.V526.Document.Document
    , documents : List Evergreen.V526.Document.Document
    , pinnedDocuments : List Evergreen.V526.Document.DocumentInfo
    , publicDocuments : List Evergreen.V526.Document.Document
    , initialText : String
    , sourceText : String
    , editRecord : Evergreen.V526.Compiler.DifferentialParser.EditRecord
    , tableOfContents : List Evergreen.V526.Parser.Block.ExpressionBlock
    , title : String
    , lineNumber : Int
    , permissions : DocumentHandling
    , debounce : Debounce.Debounce String
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
    , language : Evergreen.V526.Parser.Language.Language
    }


type alias GroupName =
    String


type alias ChatDict =
    Dict.Dict GroupName (List Evergreen.V526.Chat.Message.ChatMessage)


type alias ChatGroupDict =
    Dict.Dict GroupName ChatGroup


type alias DocumentDict =
    Dict.Dict String Evergreen.V526.Document.Document


type alias DocId =
    String


type alias SharedDocumentDict =
    Dict.Dict DocId SharedDocument


type alias AuthorDict =
    Dict.Dict String String


type alias PublicIdDict =
    Dict.Dict String String


type alias AbstractDict =
    Dict.Dict String Evergreen.V526.Abstract.Abstract


type alias UserId =
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
    , chatDict : ChatDict
    , chatGroupDict : ChatGroupDict
    , authenticationDict : Evergreen.V526.Authentication.AuthenticationDict
    , documentDict : DocumentDict
    , sharedDocumentDict : SharedDocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , connectionDict : ConnectionDict
    , editEvents : Deque.Deque Evergreen.V526.CollaborativeEditing.NetworkModel.EditEvent
    , documents : List Evergreen.V526.Document.Document
    , publicDocuments : List Evergreen.V526.Document.Document
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
    | SignUpBE String Evergreen.V526.Parser.Language.Language String String String
    | UpdateUserWith Evergreen.V526.User.User
    | ClearChatHistory String
    | SendChatHistory String
    | InsertChatGroup ChatGroup
    | GetChatGroup String
    | ChatMsgSubmitted Evergreen.V526.Chat.Message.ChatMessage
    | ClearEditEvents UserId
    | Narrowcast Username UserId Evergreen.V526.Document.Document
    | NarrowcastExceptToSender Username UserId Evergreen.V526.Document.Document
    | UpdateSharedDocumentDict Evergreen.V526.User.User Evergreen.V526.Document.Document
    | AddEditor Evergreen.V526.User.User Evergreen.V526.Document.Document
    | RemoveEditor Evergreen.V526.User.User Evergreen.V526.Document.Document
    | InitializeNetworkModelsWithDocument Evergreen.V526.Document.Document
    | ResetNetworkModelForDocument Evergreen.V526.Document.Document
    | PushEditorEvent Evergreen.V526.CollaborativeEditing.NetworkModel.EditEvent
    | GetIncludedFiles Evergreen.V526.Document.Document (List String)
    | InsertDocument Evergreen.V526.User.User Evergreen.V526.Document.Document
    | GetCheatSheetDocument
    | RequestRefresh String
    | SignOutBE (Maybe String)
    | GetHomePage String
    | FetchDocumentById DocumentHandling Evergreen.V526.Document.DocumentId
    | FindDocumentByAuthorAndKey DocumentHandling Username String
    | GetPublicDocuments SortMode (Maybe String)
    | SaveDocument (Maybe Evergreen.V526.User.User) Evergreen.V526.Document.Document
    | SearchForDocumentsWithAuthorAndKey String
    | SearchForDocuments DocumentHandling (Maybe String) String
    | GetDocumentByPublicId String
    | GetDocumentById DocumentHandling String
    | CreateDocument (Maybe Evergreen.V526.User.User) Evergreen.V526.Document.Document
    | ApplySpecial Evergreen.V526.User.User String
    | HardDeleteDocumentBE Evergreen.V526.Document.Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type BackendMsg
    = ClientConnected Lamdera.SessionId Lamdera.ClientId
    | ClientDisconnected Lamdera.SessionId Lamdera.ClientId
    | GotAtomsphericRandomNumber (Result Http.Error String)
    | DelaySendingDocument Lamdera.ClientId Evergreen.V526.Document.Document
    | Tick Time.Posix


type ToFrontend
    = SendBackupData String
    | GotUsersWithOnlineStatus (List ( String, Int ))
    | GotConnectionList (List String)
    | GotShareDocumentList (List ( String, Bool, SharedDocument ))
    | UserMessageReceived UserMessage
    | UndeliverableMessage UserMessage
    | UserSignedUp Evergreen.V526.User.User
    | GotChatHistory (List ChatMsg)
    | GotChatGroup (Maybe ChatGroup)
    | ChatMessageReceived ChatMsg
    | ResetNetworkModel Evergreen.V526.CollaborativeEditing.NetworkModel.NetworkModel Evergreen.V526.Document.Document
    | InitializeNetworkModel Evergreen.V526.CollaborativeEditing.NetworkModel.NetworkModel
    | ProcessEvent Evergreen.V526.CollaborativeEditing.NetworkModel.EditEvent
    | GotIncludedData Evergreen.V526.Document.Document (List ( String, String ))
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
    | ReceivedDocument DocumentHandling Evergreen.V526.Document.Document
    | ReceivedNewDocument DocumentHandling Evergreen.V526.Document.Document
    | ReceivedDocuments DocumentHandling (List Evergreen.V526.Document.Document)
    | ReceivedPublicDocuments (List Evergreen.V526.Document.Document)
    | MessageReceived Message
    | StatusReport (List String)
    | SetShowEditor Bool
