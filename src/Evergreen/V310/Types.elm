module Evergreen.V310.Types exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation
import Debounce
import Dict
import Evergreen.V310.Abstract
import Evergreen.V310.Authentication
import Evergreen.V310.Compiler.DifferentialParser
import Evergreen.V310.Document
import Evergreen.V310.Parser.Block
import Evergreen.V310.Parser.Language
import Evergreen.V310.Render.Msg
import Evergreen.V310.User
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
    , share : Evergreen.V310.Document.Share
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
    | SharePopup


type ToggleChatGroupDisplay
    = TCGDisplay
    | TCGShowInputForm


type SystemDocPermissions
    = SystemReadOnly
    | SystemCanEdit


type DocumentDeleteState
    = WaitingForDeleteAction
    | CanDelete


type SortMode
    = SortAlphabetically
    | SortByMostRecent


type DocumentList
    = WorkingList
    | StandardList
    | SharedDocumentList


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
    | SetUserLanguage Evergreen.V310.Parser.Language.Language
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
    | UnlockCurrentDocument
    | DismissUserMessage
    | Narrow String Evergreen.V310.Document.Document
    | LockCurrentDocument
    | UnLockCurrentDocument
    | ShareDocument
    | DoShare
    | AskToClearChatHistory
    | ScrollChatToBottom
    | MakeCurrentChatGroupPreferred
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
    | SetDocumentCurrent Evergreen.V310.Document.Document
    | GetPinnedDocuments
    | SetLanguage Bool Evergreen.V310.Parser.Language.Language
    | Fetch String
    | SetPublicDocumentAsCurrentById String
    | SetInitialEditorContent
    | SetDocumentInPhoneAsCurrent SystemDocPermissions Evergreen.V310.Document.Document
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
    | SetDocumentAsCurrent SystemDocPermissions Evergreen.V310.Document.Document
    | SetPublic Evergreen.V310.Document.Document Bool
    | AskForDocumentById String
    | AskForDocumentByAuthorId
    | DeleteDocument
    | SetDeleteDocumentState DocumentDeleteState
    | Render Evergreen.V310.Render.Msg.MarkupMsg
    | SetSortMode SortMode
    | SelectList DocumentList
    | GetUserTags String
    | GetPublicTags
    | ExportToMarkdown
    | ExportToLaTeX
    | ExportTo Evergreen.V310.Parser.Language.Language
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


type SidebarState
    = SidebarIn
    | SidebarOut


type TagSelection
    = TagNeither
    | TagPublic
    | TagUser


type alias Username =
    String


type alias ChatMessage =
    { sender : String
    , group : String
    , subject : String
    , content : String
    , date : Time.Posix
    }


type ChatMsg
    = JoinedChat Lamdera.ClientId Username
    | LeftChat Lamdera.ClientId Username
    | ChatMsg Lamdera.ClientId ChatMessage


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
    , statusReport : List String
    , inputSpecial : String
    , userList : List ( Evergreen.V310.User.User, Int )
    , connectedUsers : List String
    , shareDocumentList : List ( String, SharedDocument )
    , userMessage : Maybe UserMessage
    , currentUser : Maybe Evergreen.V310.User.User
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputLanguage : Evergreen.V310.Parser.Language.Language
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
    , docLoaded : DocLoaded
    , documentsCreatedCounter : Int
    , initialText : String
    , sourceText : String
    , inputTitle : String
    , editRecord : Evergreen.V310.Compiler.DifferentialParser.EditRecord
    , tableOfContents : List Evergreen.V310.Parser.Block.ExpressionBlock
    , title : String
    , searchCount : Int
    , searchSourceText : String
    , lineNumber : Int
    , permissions : SystemDocPermissions
    , debounce : Debounce.Debounce String
    , currentDocument : Maybe Evergreen.V310.Document.Document
    , currentMasterDocument : Maybe Evergreen.V310.Document.Document
    , documents : List Evergreen.V310.Document.Document
    , publicDocuments : List Evergreen.V310.Document.Document
    , inputSearchKey : String
    , inputSearchTagsKey : String
    , inputReaders : String
    , inputEditors : String
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , deleteDocumentState : DocumentDeleteState
    , sortMode : SortMode
    , language : Evergreen.V310.Parser.Language.Language
    }


type alias GroupName =
    String


type alias ChatDict =
    Dict.Dict GroupName (List ChatMessage)


type alias ChatGroupDict =
    Dict.Dict GroupName ChatGroup


type alias DocumentDict =
    Dict.Dict String Evergreen.V310.Document.Document


type alias SharedDocumentDict =
    Dict.Dict String SharedDocument


type alias AuthorDict =
    Dict.Dict String String


type alias PublicIdDict =
    Dict.Dict String String


type alias AbstractDict =
    Dict.Dict String Evergreen.V310.Abstract.Abstract


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
    , authenticationDict : Evergreen.V310.Authentication.AuthenticationDict
    , documentDict : DocumentDict
    , sharedDocumentDict : SharedDocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , connectionDict : ConnectionDict
    , documents : List Evergreen.V310.Document.Document
    , publicDocuments : List Evergreen.V310.Document.Document
    }


type ToBackend
    = RunTask
    | GetStatus
    | GetUserList
    | GetSharedDocuments String
    | ClearConnectionDictBE
    | DeliverUserMessage UserMessage
    | SignInBE String String
    | SignUpBE String Evergreen.V310.Parser.Language.Language String String String
    | UpdateUserWith Evergreen.V310.User.User
    | ClearChatHistory String
    | SendChatHistory String
    | InsertChatGroup ChatGroup
    | GetChatGroup String
    | ChatMsgSubmitted ChatMessage
    | Narrowcast String Evergreen.V310.Document.Document
    | UpdateSharedDocumentDict Evergreen.V310.Document.Document
    | RequestRefresh String
    | SignOutBE (Maybe String)
    | GetHomePage String
    | FetchDocumentById String (Maybe String)
    | GetPublicDocuments SortMode (Maybe String)
    | SaveDocument Evergreen.V310.Document.Document
    | SearchForDocumentsWithAuthorAndKey String
    | GetDocumentByPublicId String
    | GetDocumentById String
    | CreateDocument (Maybe Evergreen.V310.User.User) Evergreen.V310.Document.Document
    | ApplySpecial Evergreen.V310.User.User String
    | SearchForDocuments (Maybe String) String
    | DeleteDocumentBE Evergreen.V310.Document.Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type BackendMsg
    = ClientConnected Lamdera.SessionId Lamdera.ClientId
    | ClientDisconnected Lamdera.SessionId Lamdera.ClientId
    | GotAtomsphericRandomNumber (Result Http.Error String)
    | DelaySendingDocument Lamdera.ClientId Evergreen.V310.Document.Document
    | Tick Time.Posix


type ToFrontend
    = SendBackupData String
    | GotUserList (List ( Evergreen.V310.User.User, Int ))
    | GotConnectionList (List String)
    | GotShareDocumentList (List ( String, SharedDocument ))
    | UserMessageReceived UserMessage
    | UndeliverableMessage UserMessage
    | UserSignedUp Evergreen.V310.User.User
    | GotChatHistory
    | GotChatGroup (Maybe ChatGroup)
    | MessageReceived ChatMsg
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
    | SendDocument SystemDocPermissions Evergreen.V310.Document.Document
    | ReceivedDocuments (List Evergreen.V310.Document.Document)
    | ReceivedPublicDocuments (List Evergreen.V310.Document.Document)
    | SendMessage Message
    | StatusReport (List String)
    | SetShowEditor Bool
