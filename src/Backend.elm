module Backend exposing
    ( Model
    , app
    , authorLink
    , authorUrl
    , filterDict
    , getAbstract
    , init
    , makeLink
    , publicLink
    , publicUrl
    , putAbstract
    , searchInAbstract
    , statusReport
    , stealId
    , update
    , updateAbstracts
    , updateFromFrontend
    )

import Abstract exposing (Abstract)
import Authentication
import Backend.Chat
import Backend.Cmd
import Backend.NetworkModel
import Backend.Update
import Chat
import CollaborativeEditing.NetworkModel as NetworkModel
import Config
import Deque
import Dict exposing (Dict)
import Docs
import Document
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription
import Effect.Time
import Env
import Lamdera
import Maybe.Extra
import Random
import Share
import Types exposing (AbstractDict, BackendModel, BackendMsg(..), DocumentDict, DocumentLink, ToBackend(..), ToFrontend(..))
import User exposing (User)
import Util


type alias Model =
    BackendModel


app =
    Effect.Lamdera.backend
        Lamdera.broadcast
        Lamdera.sendToFrontend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \_ -> subscriptions
        }


subscriptions =
    Subscription.batch
        [ Effect.Lamdera.onConnect ClientConnected
        , Effect.Lamdera.onDisconnect ClientDisconnected
        , Effect.Time.every (Duration.milliseconds (Config.backendTickSeconds * 1000)) Tick
        ]


{-| TODO: Martin -- is this OK
-}
init : ( Model, Command BackendOnly ToFrontend BackendMsg )
init =
    ( { message = "Hello!"

      -- RANDOM
      , randomSeed = Random.initialSeed 1234
      , uuidCount = 0
      , randomAtmosphericInt = Nothing
      , currentTime = Effect.Time.millisToPosix 0

      -- USER
      , authenticationDict = Dict.empty

      -- CHAT
      , chatDict = Dict.empty
      , chatGroupDict = Dict.empty

      -- DATA
      , documentDict = Dict.empty
      , slugDict = Dict.empty
      , sharedDocumentDict = Dict.empty
      , authorIdDict = Dict.empty
      , publicIdDict = Dict.empty
      , abstractDict = Dict.empty
      , usersDocumentsDict = Dict.empty
      , publicDocuments = []
      , connectionDict = Dict.empty

      -- DOCUMENTS
      , editEvents = Deque.empty
      , documents =
            [ Docs.docsNotFound
            , Docs.notSignedIn
            ]
      }
    , Backend.Cmd.getRandomNumber
    )



-- UPDATE BACKEND


update : BackendMsg -> Model -> ( Model, Command BackendOnly ToFrontend BackendMsg )
update msg model =
    case msg of
        GotAtomsphericRandomNumber result ->
            Backend.Update.gotAtmosphericRandomNumber model result

        ClientConnected _ _ ->
            ( model, Command.none )

        ClientDisconnected sessionId clientId ->
            Backend.Update.removeSessionClient model sessionId clientId

        DelaySendingDocument clientId doc ->
            ( model
            , Command.batch
                [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocument Types.HandleAsManual doc)
                , Effect.Lamdera.sendToFrontend clientId
                    (MessageReceived
                        { txt = doc.title ++ ", currentEditor = " ++ (doc.currentEditorList |> List.map .username |> String.join ", ")
                        , status = Types.MSYellow
                        }
                    )
                ]
            )

        Tick newTime ->
            -- Do regular tasks
            ( { model | currentTime = newTime }
                |> updateAbstracts
                |> Backend.Update.updateDocumentTags
            , Command.none
            )



-- UPDATE FROM FRONTEND


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        -- CHAT
        ClearChatHistory groupName ->
            let
                newChatDict =
                    Dict.insert groupName [] model.chatDict

                newModel =
                    { model | chatDict = newChatDict }
            in
            ( newModel, Chat.sendChatHistoryCmd groupName newModel )

        SendChatHistory groupName ->
            case Dict.get groupName model.chatGroupDict of
                Nothing ->
                    ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = groupName ++ ": no such group", status = Types.MSYellow }) )

                Just _ ->
                    ( model, Chat.sendChatHistoryCmd groupName model )

        InsertChatGroup group ->
            ( { model | chatGroupDict = Dict.insert group.name group model.chatGroupDict }, Command.none )

        GetChatGroup groupName ->
            ( model, Effect.Lamdera.sendToFrontend clientId (GotChatGroup (Dict.get groupName model.chatGroupDict)) )

        ChatMsgSubmitted message ->
            Backend.Chat.msgSubmitted model message

        -- ( { model | chatDict = Chat.Message.insert message model.chatDict }, Cmd.batch (Chat.narrowCast model message) )
        DeliverUserMessage usermessage ->
            Backend.Update.deliverUserMessage model clientId usermessage

        -- SHARE
        InitializeNetworkModelsWithDocument doc ->
            let
                currentEditorList =
                    doc.currentEditorList

                userIds =
                    List.map .userId currentEditorList

                clients : List ClientId
                clients =
                    List.foldl (\editorName acc -> Dict.get editorName model.connectionDict :: acc) [] (List.map .username currentEditorList)
                        |> Maybe.Extra.values
                        |> List.concat
                        |> List.map .client

                networkModel =
                    NetworkModel.initWithUsersAndContent doc.id userIds doc.content

                sharedDocument_ =
                    Share.toSharedDocument doc

                sharedDocument : Types.SharedDocument
                sharedDocument =
                    { sharedDocument_ | currentEditors = doc.currentEditorList }

                sharedDocumentDict =
                    Dict.insert doc.id sharedDocument model.sharedDocumentDict

                cmds =
                    List.map (\clientId_ -> Effect.Lamdera.sendToFrontend clientId_ (InitializeNetworkModel networkModel)) clients
            in
            ( { model | sharedDocumentDict = sharedDocumentDict }, Command.batch cmds )

        ResetNetworkModelForDocument doc ->
            let
                currentEditorList =
                    doc.currentEditorList

                document =
                    { doc | currentEditorList = [] }

                clients : List ClientId
                clients =
                    List.foldl (\editorName acc -> Dict.get editorName model.connectionDict :: acc) [] (List.map .username currentEditorList)
                        |> Maybe.Extra.values
                        |> List.concat
                        |> List.map .client

                networkModel =
                    NetworkModel.initWithUsersAndContent "--fake--" [] ""

                cmds =
                    List.map (\clientId_ -> Effect.Lamdera.sendToFrontend clientId_ (ResetNetworkModel networkModel document)) clients
            in
            ( model, Command.batch cmds )

        PushEditorEvent event ->
            Backend.NetworkModel.processEvent event model

        UpdateSharedDocumentDict doc ->
            ( Share.updateSharedDocumentDict doc model, Command.none )

        AddEditor user doc ->
            let
                sharedDocumentDict =
                    Share.update user.username user.id doc clientId model.sharedDocumentDict
            in
            ( { model | sharedDocumentDict = sharedDocumentDict }, Share.narrowCastToEditorsExceptForSender user.username doc model.connectionDict )

        RemoveEditor _ _ ->
            ( model, Command.none )

        Narrowcast sendersName sendersId document ->
            ( { model | sharedDocumentDict = Share.update sendersName sendersId document clientId model.sharedDocumentDict }, Share.narrowCast clientId document model.connectionDict )

        -- Narrowcast document changes to other editors of shared document
        NarrowcastExceptToSender sendersName sendersId document ->
            ( { model | sharedDocumentDict = Share.update sendersName sendersId document clientId model.sharedDocumentDict }, Share.narrowCastToEditorsExceptForSender sendersName document model.connectionDict )

        ClearConnectionDictBE ->
            ( { model | connectionDict = Dict.empty }, Command.none )

        RequestRefresh docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model, Command.none )

                Just doc ->
                    let
                        message =
                            { txt = "Refreshing " ++ doc.title ++ " with currentEditor = " ++ (doc.currentEditorList |> List.map .username |> String.join ", "), status = Types.MSGreen }
                    in
                    ( model
                    , Command.batch
                        [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocument Types.HandleAsManual doc)
                        , Effect.Lamdera.sendToFrontend clientId (MessageReceived message)
                        ]
                    )

        -- SIGN IN - UP - OUt
        SignInBE username encryptedPassword ->
            Backend.Update.signIn model sessionId clientId username encryptedPassword

        SignUpBE username lang encryptedPassword realname email ->
            Backend.Update.signUpUser model sessionId clientId username lang encryptedPassword realname email

        SignOutBE mUsername ->
            case mUsername of
                Nothing ->
                    ( model, Command.none )

                Just username ->
                    case Env.mode of
                        Env.Production ->
                            Backend.Update.signOut model username clientId

                        Env.Development ->
                            Backend.Update.signOut model username clientId
                                |> (\( m1, c1 ) ->
                                        let
                                            ( m2, c2 ) =
                                                -- Backend.Update.cleanup m1 sessionId clientId
                                                ( m1, c1 )
                                        in
                                        ( m2, Command.batch [ c1, c2 ] )
                                   )

        -- ????
        RunTask ->
            ( model, Command.none )

        GetStatus ->
            ( model, Effect.Lamdera.sendToFrontend clientId (StatusReport (statusReport model)) )

        -- USER
        GetUsersWithOnlineStatus ->
            ( model
            , Command.batch
                [ Effect.Lamdera.sendToFrontend clientId (GotUsersWithOnlineStatus (Backend.Update.getUsersAndOnlineStatus model))
                ]
            )

        GetUserList ->
            let
                isConnected username =
                    case Dict.get username model.connectionDict of
                        Nothing ->
                            False

                        Just _ ->
                            True
            in
            ( model
            , Command.batch
                [ Effect.Lamdera.sendToFrontend clientId (GotUsersWithOnlineStatus (Backend.Update.getUserAndDocumentData model))
                , Effect.Lamdera.sendToFrontend clientId (GotConnectionList (Backend.Update.getConnectionData model))
                , Effect.Lamdera.sendToFrontend clientId
                    (GotShareDocumentList
                        (model.sharedDocumentDict
                            |> Dict.toList
                            |> List.map (\( username_, data ) -> ( data.author |> Maybe.withDefault "(anon)", isConnected username_, data ))
                        )
                    )
                ]
            )

        UpdateUserWith user ->
            ( { model | authenticationDict = Authentication.updateUser user model.authenticationDict }, Command.none )

        -- SEARCH
        SearchForDocumentsWithAuthorAndKey segment ->
            Backend.Update.searchForDocumentsByAuthorAndKey model clientId segment

        SearchForDocuments documentHandling currentUser key ->
            -- TODO: Refactor!
            case currentUser of
                Nothing ->
                    Backend.Update.searchForDocuments model clientId documentHandling currentUser key

                Just user ->
                    if key == "" then
                        let
                            docs =
                                Backend.Update.getMostRecentUserDocuments Types.SortByMostRecent Config.maxDocSearchLimit user model.usersDocumentsDict model.documentDict
                        in
                        ( model, Effect.Lamdera.sendToFrontend clientId (ReceivedDocuments documentHandling docs) )

                    else
                        Backend.Update.searchForDocuments model clientId documentHandling currentUser key

        FindDocumentByAuthorAndKey documentHandling authorName searchKey ->
            Backend.Update.findDocumentByAuthorAndKey model clientId documentHandling authorName searchKey

        -- DOCUMENT
        DeleteDocumentsWithIds ids ->
            ( Backend.Update.hardDeleteDocumentsWithIdList ids model, Command.none )

        MakeCollection title username tag ->
            let
                docInfo =
                    Backend.Update.getUserDocumentsForAuthor username model
                        |> List.filter (\doc -> List.member tag doc.tags)
                        |> List.sortBy (\doc -> String.toLower doc.title)
                        |> List.map makeDocLink
                        |> String.join "\n\n"

                makeDocLink doc =
                    "| document " ++ doc.id ++ "\n" ++ doc.title

                content =
                    "| title\n[" ++ title ++ "]\n\n| collection\n\n" ++ docInfo

                emptyDoc =
                    Document.empty

                collectionDoc =
                    { emptyDoc | title = title, id = "jxxcarlson:folder-" ++ title, content = content }
            in
            ( model, Effect.Lamdera.sendToFrontend clientId (ReceivedDocument Types.StandardHandling collectionDoc) )

        GetSharedDocuments username ->
            Backend.Update.getSharedDocuments model clientId username

        FetchDocumentById documentHandling docId ->
            Backend.Update.fetchDocumentById model clientId docId documentHandling

        GetDocumentByPublicId publicId ->
            Backend.Update.getDocumentByPublicId model clientId publicId

        GetPublicDocuments sortMode mUsername ->
            ( model, Effect.Lamdera.sendToFrontend clientId (ReceivedPublicDocuments (Backend.Update.searchForPublicDocuments sortMode Config.maxDocSearchLimit mUsername "startup" model)) )

        -- DOCUMENTS
        ClearEditEvents userId ->
            ( { model | editEvents = Deque.filter (\evt -> evt.userId /= userId) model.editEvents }, Command.none )

        GetIncludedFiles doc fileList ->
            let
                tuplify : List String -> Maybe ( String, String )
                tuplify strs =
                    case strs of
                        a :: b :: [] ->
                            Just ( a, b )

                        _ ->
                            Nothing

                authorsAndKeys : List ( String, String )
                authorsAndKeys =
                    List.map (String.split ":" >> tuplify) fileList |> Maybe.Extra.values

                getContent : ( String, String ) -> String
                getContent ( author, key ) =
                    Backend.Update.findDocumentByAuthorAndKey_ model author (author ++ ":" ++ key)
                        |> Maybe.map .content
                        |> Maybe.withDefault ""
                        |> String.lines
                        |> Util.discardLines (\line -> String.startsWith "[tags" line)
                        |> String.join "\n"
                        |> String.trim

                -- List (username:tag, content)
                data : List ( String, String )
                data =
                    List.foldl (\( author, key ) acc -> ( author ++ ":" ++ key, getContent ( author, key ) ) :: acc) [] authorsAndKeys

                cmd =
                    Effect.Lamdera.sendToFrontend clientId (GotIncludedData doc data)
            in
            ( model, cmd )

        InsertDocument user doc ->
            Backend.Update.insertDocument model clientId user doc

        -- TAGS
        GetUserTagsFromBE author ->
            ( model, Effect.Lamdera.sendToFrontend clientId (AcceptUserTags (Backend.Update.authorTags author model)) )

        GetPublicTagsFromBE ->
            ( model, Effect.Lamdera.sendToFrontend clientId (AcceptPublicTags (Backend.Update.publicTags model)) )

        CreateDocument maybeCurrentUser doc_ ->
            Backend.Update.createDocument model clientId maybeCurrentUser doc_

        SaveDocument currentUser document ->
            Backend.Update.saveDocument model clientId currentUser document

        GetCheatSheetDocument ->
            Backend.Update.fetchDocumentById model clientId Config.l0GuideId Types.HandleAsManual

        GetHomePage username ->
            Backend.Update.getHomePage model clientId username

        GetDocumentById documentHandling id ->
            Backend.Update.getDocumentById model clientId documentHandling id

        ApplySpecial _ _ ->
            Backend.Update.applySpecial model

        HardDeleteDocumentBE doc ->
            Backend.Update.hardDeleteDocument clientId doc model


makeLink : String -> DocumentDict -> AbstractDict -> Maybe DocumentLink
makeLink docId documentDict abstractDict =
    case ( Dict.get docId documentDict, Dict.get docId abstractDict ) of
        ( Nothing, _ ) ->
            Nothing

        ( _, Nothing ) ->
            Nothing

        ( Just doc, Just abstr ) ->
            if doc.public then
                Just { digest = abstr.digest, label = abstr.title, url = Config.host ++ "/p/" ++ doc.publicId }

            else
                Nothing


statusReport : Model -> List String
statusReport model =
    let
        pairs : List ( String, String )
        pairs =
            Dict.toList model.authorIdDict

        gist documentId =
            Dict.get documentId model.documentDict
                |> Maybe.map .content
                |> Maybe.withDefault "(empty)"
                |> String.trimLeft
                |> String.left 60
                |> String.replace "\n\n" "\n"
                |> String.replace "\n" " ~ "

        items : List String
        items =
            List.map (\( a, b ) -> authorUrl a ++ " : " ++ b ++ " : " ++ gist b) pairs

        abstracts : List String
        abstracts =
            Dict.values model.abstractDict |> List.map Abstract.toString

        firstEntry : String
        firstEntry =
            "Atmospheric Int: " ++ (Maybe.map String.fromInt model.randomAtmosphericInt |> Maybe.withDefault "Nothing")

        secondEntry =
            "Dictionary size: " ++ String.fromInt (List.length pairs)
    in
    firstEntry :: secondEntry :: items ++ abstracts


authorUrl : String -> String
authorUrl authorId =
    Config.host ++ "/a/" ++ authorId


authorLink : String -> String
authorLink authorId =
    "[Author](" ++ authorUrl authorId ++ ")"


publicUrl : String -> String
publicUrl publicId =
    Config.host ++ "/p/" ++ publicId


publicLink : String -> String
publicLink publicId =
    "[Public](" ++ publicUrl publicId ++ ")"


updateAbstracts : Model -> Model
updateAbstracts model =
    { model | abstractDict = Backend.Update.updateAbstracts model.documentDict model.abstractDict }


stealId : User -> String -> Model -> Model
stealId user id model =
    case Dict.get id model.documentDict of
        Nothing ->
            model

        Just _ ->
            let
                newUser =
                    user

                newAuthDict =
                    Authentication.updateUser newUser model.authenticationDict
            in
            { model | authenticationDict = newAuthDict }


putAbstract : String -> DocumentDict -> AbstractDict -> AbstractDict
putAbstract docId documentDict abstractDict =
    Dict.insert docId (getAbstract documentDict docId) abstractDict


getAbstract : Dict String Document.Document -> String -> Abstract
getAbstract documentDict id =
    case Dict.get id documentDict of
        Nothing ->
            Abstract.empty

        Just doc ->
            let
                abstr =
                    Abstract.get doc.author doc.language doc.content
            in
            { abstr | digest = abstr.digest ++ " " ++ doc.id }


searchInAbstract : String -> Abstract -> Bool
searchInAbstract key abstract =
    String.contains key abstract.title


filterDict : (value -> Bool) -> Dict comparable value -> List ( comparable, value )
filterDict predicate dict =
    let
        filter key_ dict_ =
            case Dict.get key_ dict_ of
                Nothing ->
                    Nothing

                Just value ->
                    if predicate value then
                        Just ( key_, value )

                    else
                        Nothing

        add key_ dict_ list_ =
            case filter key_ dict_ of
                Nothing ->
                    list_

                Just item ->
                    item :: list_
    in
    List.foldl (\key list_ -> add key dict list_) [] (Dict.keys dict)
