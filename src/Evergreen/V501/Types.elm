module Evergreen.V501.Types exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation
import Debounce
import Dict
import Evergreen.V501.Abstract
import Evergreen.V501.Authentication
import Evergreen.V501.Chat.Message
import Evergreen.V501.Compiler.DifferentialParser
import Evergreen.V501.Document
import Evergreen.V501.Parser.Block
import Evergreen.V501.Parser.Language
import Evergreen.V501.Render.Msg
import Evergreen.V501.User
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
    , share : Evergreen.V501.Document.Share
    , currentEditor : Maybe String
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


type ToggleChatGroupDisplay
    = TCGDisplay
    | TCGShowInputForm


type DocumentHandling
    = StandardHandling
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
    | Render Evergreen.V501.Render.Msg.MarkupMsg
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
    | InputUsername String
    | InputPassword String
    | InputPasswordAgain String
    | InputRealname String
    | InputEmail String
    | SetUserLanguage Evergreen.V501.Parser.Language.Language
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
    | Narrow String Evergreen.V501.Document.Document
    | LockCurrentDocument
    | UnLockCurrentDocument
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
    | SetDocumentStatus Evergreen.V501.Document.DocStatus
    | ChangeLanguage
    | MakeBackup
    | ToggleBackupVisibility
    | SetDocumentCurrent Evergreen.V501.Document.Document
    | SetDocumentCurrentViaId Evergreen.V501.Document.DocumentId
    | GetPinnedDocuments
    | SetLanguage Bool Evergreen.V501.Parser.Language.Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent DocumentHandling Evergreen.V501.Document.Document
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
    | SetDocumentAsCurrent DocumentHandling Evergreen.V501.Document.Document
    | SetPublic Evergreen.V501.Document.Document Bool
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
    | ExportTo Evergreen.V501.Parser.Language.Language
    | Export
    | PrintToPDF
    | GotPdfLink (Result Http.Error String)
    | ChangePrintingState PrintingState
    | FinallyDoCleanPrintArtefacts String
    | Help String


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


type SidebarExtrasState
    = SidebarExtrasIn
    | SidebarExtrasOut


type SidebarTagsState
    = SidebarTagsIn
    | SidebarTagsOut


type TagSelection
    = TagPublic
    | TagUser


type alias Username =
    String


type ChatMsg
    = JoinedChat Lamdera.ClientId Username
    | LeftChat Lamdera.ClientId Username
    | ChatMsg Lamdera.ClientId Evergreen.V501.Chat.Message.ChatMessage


type alias ChatGroup =
    { name : String
    , members : List Username
    , owner : Username
    , assistant : Maybe Username
    }


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
    , currentUser : Maybe Evergreen.V501.User.User
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputLanguage : Evergreen.V501.Parser.Language.Language
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
    , showEditor : Bool
    , authorId : String
    , phoneMode : PhoneMode
    , pressedKeys : List Keyboard.Key
    , activeDocList : ActiveDocList
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
    , doSync : Bool
    , includedContent : Dict.Dict String String
    , documentDirty : Bool
    , seeBackups : Bool
    , publicDocumentSearchKey : String
    , docLoaded : DocLoaded
    , documentsCreatedCounter : Int
    , initialText : String
    , sourceText : String
    , inputTitle : String
    , showDocTools : Bool
    , showPublicUrl : Bool
    , editRecord : Evergreen.V501.Compiler.DifferentialParser.EditRecord
    , tableOfContents : List Evergreen.V501.Parser.Block.ExpressionBlock
    , title : String
    , searchCount : Int
    , searchSourceText : String
    , lineNumber : Int
    , permissions : DocumentHandling
    , debounce : Debounce.Debounce String
    , currentDocument : Maybe Evergreen.V501.Document.Document
    , currentCheatsheet : Maybe Evergreen.V501.Document.Document
    , currentMasterDocument : Maybe Evergreen.V501.Document.Document
    , documents : List Evergreen.V501.Document.Document
    , pinnedDocuments : List Evergreen.V501.Document.DocumentInfo
    , publicDocuments : List Evergreen.V501.Document.Document
    , inputSearchKey : String
    , actualSearchKey : String
    , inputSearchTagsKey : String
    , inputReaders : String
    , inputEditors : String
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , deleteDocumentState : DocumentDeleteState
    , hardDeleteDocumentState : DocumentHardDeleteState
    , sortMode : SortMode
    , language : Evergreen.V501.Parser.Language.Language
    }


type alias GroupName =
    String


type alias ChatDict =
    Dict.Dict GroupName (List Evergreen.V501.Chat.Message.ChatMessage)


type alias ChatGroupDict =
    Dict.Dict GroupName ChatGroup


type alias DocumentDict =
    Dict.Dict String Evergreen.V501.Document.Document


type alias SharedDocumentDict =
    Dict.Dict String SharedDocument


type alias AuthorDict =
    Dict.Dict String String


type alias PublicIdDict =
    Dict.Dict String String


type alias AbstractDict =
    Dict.Dict String Evergreen.V501.Abstract.Abstract


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
    , chatDict : ChatDict
    , chatGroupDict : ChatGroupDict
    , authenticationDict : Evergreen.V501.Authentication.AuthenticationDict
    , documentDict : DocumentDict
    , sharedDocumentDict : SharedDocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , connectionDict : ConnectionDict
    , documents : List Evergreen.V501.Document.Document
    , publicDocuments : List Evergreen.V501.Document.Document
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
    | SignUpBE String Evergreen.V501.Parser.Language.Language String String String
    | UpdateUserWith Evergreen.V501.User.User
    | ClearChatHistory String
    | SendChatHistory String
    | InsertChatGroup ChatGroup
    | GetChatGroup String
    | ChatMsgSubmitted Evergreen.V501.Chat.Message.ChatMessage
    | Narrowcast String Evergreen.V501.Document.Document
    | UpdateSharedDocumentDict Evergreen.V501.Document.Document
    | GetIncludedFiles Evergreen.V501.Document.Document (List String)
    | InsertDocument Evergreen.V501.User.User Evergreen.V501.Document.Document
    | GetCheatSheetDocument
    | RequestRefresh String
    | SignOutBE (Maybe String)
    | GetHomePage String
    | FetchDocumentById DocumentHandling Evergreen.V501.Document.DocumentId
    | FindDocumentByAuthorAndKey DocumentHandling Username String
    | GetPublicDocuments SortMode (Maybe String)
    | SaveDocument Evergreen.V501.Document.Document
    | SearchForDocumentsWithAuthorAndKey String
    | SearchForDocuments DocumentHandling (Maybe String) String
    | GetDocumentByPublicId String
    | GetDocumentById DocumentHandling String
    | CreateDocument (Maybe Evergreen.V501.User.User) Evergreen.V501.Document.Document
    | ApplySpecial Evergreen.V501.User.User String
    | HardDeleteDocumentBE Evergreen.V501.Document.Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type BackendMsg
    = ClientConnected Lamdera.SessionId Lamdera.ClientId
    | ClientDisconnected Lamdera.SessionId Lamdera.ClientId
    | GotAtomsphericRandomNumber (Result Http.Error String)
    | DelaySendingDocument Lamdera.ClientId Evergreen.V501.Document.Document
    | Tick Time.Posix


type ToFrontend
    = SendBackupData String
    | GotUsersWithOnlineStatus (List ( String, Int ))
    | GotConnectionList (List String)
    | GotShareDocumentList (List ( String, Bool, SharedDocument ))
    | UserMessageReceived UserMessage
    | UndeliverableMessage UserMessage
    | UserSignedUp Evergreen.V501.User.User
    | GotChatHistory (List ChatMsg)
    | GotChatGroup (Maybe ChatGroup)
    | ChatMessageReceived ChatMsg
    | GotIncludedData Evergreen.V501.Document.Document (List ( String, String ))
    | SmartUnLockCurrentDocument
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
    | ReceivedDocument DocumentHandling Evergreen.V501.Document.Document
    | ReceivedNewDocument DocumentHandling Evergreen.V501.Document.Document
    | ReceivedDocuments DocumentHandling (List Evergreen.V501.Document.Document)
    | ReceivedPublicDocuments (List Evergreen.V501.Document.Document)
    | MessageReceived Message
    | StatusReport (List String)
    | SetShowEditor Bool
    | UnlockDocument Evergreen.V501.Document.DocumentId
