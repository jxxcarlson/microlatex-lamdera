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
    , ChatMessage
    , ChatMsg(..)
    , ConnectionData
    , ConnectionDict
    , DocId
    , DocLoaded(..)
    , DocumentDeleteState(..)
    , DocumentDict
    , DocumentLink
    , DocumentList(..)
    , FailureAction(..)
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
    , SharedDocument
    , SharedDocumentDict
    , SidebarState(..)
    , SignupState(..)
    , SortMode(..)
    , SystemDocPermissions(..)
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
import Browser.Dom as Dom
import Browser.Navigation
import Compiler.DifferentialParser
import Debounce exposing (Debounce)
import Dict exposing (Dict)
import Document exposing (Document)
import Http
import Keyboard
import Lamdera exposing (ClientId, SessionId)
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
    , currentTime : Time.Posix
    , zone : Time.Zone

    -- ADMIN
    , statusReport : List String
    , inputSpecial : String
    , userList : List ( User, Int )
    , connectedUsers : List String
    , shareDocumentList : List ( String, SharedDocument )

    -- USER
    , userMessage : Maybe UserMessage
    , currentUser : Maybe User
    , inputUsername : String
    , inputPassword : String
    , inputPasswordAgain : String
    , inputRealname : String
    , inputEmail : String
    , inputLanguage : Language
    , tagDict : Dict String (List { id : String, title : String })
    , publicTagDict : Dict String (List { id : String, title : String })
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
    , syncRequestIndex : Int
    , linenumber : Int
    , doSync : Bool

    -- DOCUMENT
    , publicDocumentSearchKey : String
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
    , publicDocuments : List Document
    , inputSearchKey : String
    , actualSearchKey : String
    , inputSearchTagsKey : String
    , inputReaders : String
    , inputEditors : String
    , printingState : PrintingState
    , documentDeleteState : DocumentDeleteState
    , counter : Int
    , deleteDocumentState : DocumentDeleteState
    , sortMode : SortMode
    , language : Language
    }


type ToggleChatGroupDisplay
    = TCGDisplay
    | TCGShowInputForm


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
    | UserMessagePopup
    | SharePopup


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

    -- CHAT
    , chatDict : ChatDict
    , chatGroupDict : ChatGroupDict

    -- USER
    , authenticationDict : AuthenticationDict

    -- DATA
    , documentDict : DocumentDict
    , sharedDocumentDict : SharedDocumentDict
    , authorIdDict : AuthorDict
    , publicIdDict : PublicIdDict
    , abstractDict : AbstractDict
    , usersDocumentsDict : UsersDocumentsDict
    , connectionDict : ConnectionDict

    -- DOCUMENT
    , documents : List Document
    , publicDocuments : List Document
    }


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


{-| User id -> List docId
-}
type alias UsersDocumentsDict =
    Dict UserId (List DocId)


type alias SharedDocument =
    { title : String
    , id : String
    , author : Maybe String
    , share : Document.Share
    , currentEditor : Maybe String -- Just user name of current editor if there is one
    }


{-| key = docId
-}
type alias SharedDocumentDict =
    Dict String SharedDocument



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



-- CHAT


type alias ChatDict =
    Dict GroupName (List ChatMessage)


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
    | ChatMsg ClientId ChatMessage


type alias GroupName =
    String


type alias ChatMessage =
    { sender : String
    , group : String
    , subject : String
    , content : String
    , date : Time.Posix
    }


type alias Username =
    String



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


type FrontendMsg
    = FENoOp
    | UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | FETick Time.Posix
    | AdjustTimeZone Time.Zone
    | GotTime Time.Posix
      -- UI
    | OpenSharedDocumentList
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
    | ClearConnectionDict
      -- USER
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
      -- SHARE
    | DismissUserMessage
    | Narrow String Document
    | LockCurrentDocument
    | UnLockCurrentDocument
    | ShareDocument
    | DoShare
      -- CHAT (FrontendMsg)
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
      -- DOC
    | SetDocumentCurrent Document
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
    | AskForDocumentById String
    | AskForDocumentByAuthorId
    | DeleteDocument
    | SetDeleteDocumentState DocumentDeleteState
    | Render Render.Msg.MarkupMsg
    | SetSortMode SortMode
    | SelectList DocumentList
    | GetUserTags
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
    | SharedDocumentList


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
    | ChatMsgSubmitted ChatMessage
      -- SHARE
    | Narrowcast String Document -- First arg is the sender's username.  Send the document
    | UpdateSharedDocumentDict Document
      -- to all users in the document's share list, plus the author, minus the sender who have active connections
      -- DOCUMENT
    | RequestRefresh String
    | SignOutBE (Maybe String)
    | GetHomePage String
    | FetchDocumentById String (Maybe String)
    | GetPublicDocuments SortMode (Maybe String)
    | SaveDocument Document
    | SearchForDocumentsWithAuthorAndKey String
    | SearchForDocuments (Maybe String) String
    | GetDocumentByPublicId String
    | GetDocumentById String
    | CreateDocument (Maybe User) Document
    | ApplySpecial User String
    | DeleteDocumentBE Document
    | GetUserTagsFromBE String
    | GetPublicTagsFromBE


type SignupState
    = ShowSignUpForm
    | HideSignUpForm


type BackendMsg
    = ClientConnected SessionId ClientId
    | ClientDisconnected SessionId ClientId
    | GotAtomsphericRandomNumber (Result Http.Error String)
    | DelaySendingDocument Lamdera.ClientId Document
    | Tick Time.Posix


type ToFrontend
    = -- ADMIN
      SendBackupData String
    | GotUserList (List ( User, Int ))
    | GotConnectionList (List String)
    | GotShareDocumentList (List ( String, SharedDocument ))
      -- USER
    | UserMessageReceived UserMessage
    | UndeliverableMessage UserMessage
    | UserSignedUp User
      -- CHAT
    | GotChatHistory
    | GotChatGroup (Maybe ChatGroup)
    | ChatMessageReceived ChatMsg
      -- DOCUMENT
    | SmartUnLockCurrentDocument
    | AcceptUserTags (Dict String (List { id : String, title : String }))
    | AcceptPublicTags (Dict String (List { id : String, title : String }))
    | ReceivedDocument SystemDocPermissions Document
    | ReceivedNewDocument SystemDocPermissions Document
    | ReceivedDocuments (List Document)
    | ReceivedPublicDocuments (List Document)
    | MessageReceived Message
    | StatusReport (List String)
    | SetShowEditor Bool
    | UnlockDocument Document.DocumentId


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
