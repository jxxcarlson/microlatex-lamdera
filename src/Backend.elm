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
import Backend.Cmd
import Backend.Update
import Chat
import Chat.Message
import Cmd.Extra
import Config
import Dict exposing (Dict)
import Docs
import Document
import Env
import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Maybe.Extra
import Message
import Random
import Share
import Time
import Tools
import Types exposing (AbstractDict, BackendModel, BackendMsg(..), DocumentDict, DocumentLink, ToBackend(..), ToFrontend(..))
import User exposing (User)
import Util


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


subscriptions model =
    Sub.batch
        [ Lamdera.onConnect ClientConnected
        , Lamdera.onDisconnect ClientDisconnected
        , Time.every (Config.backendTickSeconds * 1000) Tick
        ]


init : ( Model, Cmd BackendMsg )
init =
    ( { message = "Hello!"

      -- RANDOM
      , randomSeed = Random.initialSeed 1234
      , uuidCount = 0
      , randomAtmosphericInt = Nothing
      , currentTime = Time.millisToPosix 0

      -- USER
      , authenticationDict = Dict.empty

      -- CHAT
      , chatDict = Dict.empty
      , chatGroupDict = Dict.empty

      -- DATA
      , documentDict = Dict.empty
      , sharedDocumentDict = Dict.empty
      , authorIdDict = Dict.empty
      , publicIdDict = Dict.empty
      , abstractDict = Dict.empty
      , usersDocumentsDict = Dict.empty
      , publicDocuments = []
      , connectionDict = Dict.empty

      -- DOCUMENTS
      , editEvents = []
      , documents =
            [ Docs.docsNotFound
            , Docs.notSignedIn
            ]
      }
    , Backend.Cmd.getRandomNumber
    )



-- UPDATE BACKEND


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        GotAtomsphericRandomNumber result ->
            Backend.Update.gotAtmosphericRandomNumber model result

        ClientConnected sessionId clientId ->
            ( model, Cmd.none )

        ClientDisconnected sessionId clientId ->
            Backend.Update.removeSessionClient model sessionId clientId

        DelaySendingDocument clientId doc ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId (ReceivedDocument Types.HandleAsCheatSheet doc)
                , sendToFrontend clientId
                    (MessageReceived
                        { txt = doc.title ++ ", currentEditor = " ++ (doc.currentEditors |> List.map .username |> String.join ", ")
                        , status = Types.MSYellow
                        }
                    )
                ]
            )

        Tick newTime ->
            -- Do regular tasks
            { model | currentTime = newTime }
                |> updateAbstracts
                |> Backend.Update.updateDocumentTags
                |> Cmd.Extra.withNoCmd



-- UPDATE FROM FRONTEND


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
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
            ( newModel, Chat.sendChatHistoryCmd groupName newModel clientId )

        SendChatHistory groupName ->
            case Dict.get groupName model.chatGroupDict of
                Nothing ->
                    ( model, sendToFrontend clientId (MessageReceived { txt = groupName ++ ": no such group", status = Types.MSYellow }) )

                Just _ ->
                    ( model, Chat.sendChatHistoryCmd groupName model clientId )

        InsertChatGroup group ->
            ( { model | chatGroupDict = Dict.insert group.name group model.chatGroupDict }, Cmd.none )

        GetChatGroup groupName ->
            ( model, sendToFrontend clientId (GotChatGroup (Dict.get groupName model.chatGroupDict)) )

        ChatMsgSubmitted message ->
            if String.left 2 message.content == "!!" then
                model
                    |> Backend.Update.apply (Backend.Update.handleChatMsg message)
                    |> Backend.Update.andThenApply (Backend.Update.handlePing message)

            else
                model |> Backend.Update.apply (Backend.Update.handleChatMsg message)

        -- ( { model | chatDict = Chat.Message.insert message model.chatDict }, Cmd.batch (Chat.narrowCast model message) )
        DeliverUserMessage usermessage ->
            Backend.Update.deliverUserMessage model clientId usermessage

        -- SHARE
        PushEditorEvent event ->
            ( { model | editEvents = event :: model.editEvents |> Debug.log "!! EVENT QUEUE" }, Cmd.none )

        UpdateSharedDocumentDict user doc ->
            ( Share.updateSharedDocumentDict user doc clientId model, Cmd.none )

        Narrowcast sendersName sendersId document ->
            ( { model | sharedDocumentDict = Share.update sendersName sendersId document clientId model.sharedDocumentDict }, Share.narrowCast sendersName document model.connectionDict )

        ClearConnectionDictBE ->
            ( { model | connectionDict = Dict.empty }, Cmd.none )

        RequestRefresh docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model, Cmd.none )

                Just doc ->
                    let
                        message =
                            { txt = "Refreshing " ++ doc.title ++ " with currentEditor = " ++ (doc.currentEditors |> List.map .username |> String.join ", "), status = Types.MSGreen }
                    in
                    ( model
                    , Cmd.batch
                        [ sendToFrontend clientId (ReceivedDocument Types.HandleAsCheatSheet doc)
                        , sendToFrontend clientId (MessageReceived message)
                        ]
                    )

        SignOutBE mUsername ->
            case mUsername of
                Nothing ->
                    ( model, Cmd.none )

                Just username ->
                    case Env.mode of
                        Env.Production ->
                            Backend.Update.removeSessionClient model sessionId clientId

                        Env.Development ->
                            Backend.Update.removeSessionClient model sessionId clientId
                                |> (\( m1, c1 ) ->
                                        let
                                            ( m2, c2 ) =
                                                Backend.Update.cleanup m1 sessionId clientId
                                        in
                                        ( m2, Cmd.batch [ c1, c2 ] )
                                   )

        GetSharedDocuments username ->
            Backend.Update.getSharedDocuments model clientId username

        GetUsersWithOnlineStatus ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId (GotUsersWithOnlineStatus (Backend.Update.getUsersAndOnlineStatus model))
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
            , Cmd.batch
                [ sendToFrontend clientId (GotUsersWithOnlineStatus (Backend.Update.getUserAndDocumentData model))
                , sendToFrontend clientId (GotConnectionList (Backend.Update.getConnectionData model))
                , sendToFrontend clientId
                    (GotShareDocumentList
                        (model.sharedDocumentDict
                            |> Dict.toList
                            |> List.map (\( username_, data ) -> ( data.author |> Maybe.withDefault "(anon)", isConnected username_, data ))
                        )
                    )
                ]
            )

        RunTask ->
            ( model, Cmd.none )

        GetStatus ->
            ( model, sendToFrontend clientId (StatusReport (statusReport model)) )

        -- USER
        UpdateUserWith user ->
            ( { model | authenticationDict = Authentication.updateUser user model.authenticationDict }, Cmd.none )

        SignInBE username encryptedPassword ->
            Backend.Update.signIn model sessionId clientId username encryptedPassword

        SignUpBE username lang encryptedPassword realname email ->
            Backend.Update.signUpUser model sessionId clientId username lang encryptedPassword realname email

        -- SEARCH
        SearchForDocumentsWithAuthorAndKey segment ->
            Backend.Update.searchForDocumentsByAuthorAndKey model clientId segment

        SearchForDocuments documentHandling maybeUsername key ->
            Backend.Update.searchForDocuments model clientId documentHandling maybeUsername key

        FetchDocumentById documentHandling docId ->
            Backend.Update.fetchDocumentById model clientId docId documentHandling

        FindDocumentByAuthorAndKey documentHandling authorName searchKey ->
            Backend.Update.findDocumentByAuthorAndKey model clientId Types.StandardHandling authorName searchKey

        GetDocumentByPublicId publicId ->
            Backend.Update.getDocumentByPublicId model clientId publicId

        GetPublicDocuments sortMode mUsername ->
            ( model, sendToFrontend clientId (ReceivedPublicDocuments (Backend.Update.searchForPublicDocuments sortMode Config.maxDocSearchLimit mUsername "startup" model)) )

        -- DOCUMENTS
        ClearEditEvents userId ->
            ( { model | editEvents = List.filter (\evt -> evt.userId /= userId) model.editEvents }, Cmd.none )

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
                    sendToFrontend clientId (GotIncludedData doc data)
            in
            ( model, cmd )

        InsertDocument user doc ->
            Backend.Update.insertDocument model clientId user doc

        GetUserTagsFromBE author ->
            ( model, sendToFrontend clientId (AcceptUserTags (Backend.Update.authorTags author model)) )

        GetPublicTagsFromBE ->
            ( model, sendToFrontend clientId (AcceptPublicTags (Backend.Update.publicTags model)) )

        CreateDocument maybeCurrentUser doc_ ->
            Backend.Update.createDocument model clientId maybeCurrentUser doc_

        SaveDocument document ->
            Backend.Update.saveDocument model clientId document

        GetCheatSheetDocument ->
            Backend.Update.fetchDocumentById model clientId Config.l0CheetsheetId Types.HandleAsCheatSheet

        GetHomePage username ->
            Backend.Update.getHomePage model clientId username

        GetDocumentById documentHandling id ->
            Backend.Update.getDocumentById model clientId documentHandling id

        ApplySpecial user clientId_ ->
            Backend.Update.applySpecial model clientId_

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



--searchForDocumentsByTag : String -> Model -> List Document.Document
--searchForDocumentsByTag ta model =
--    let
--        ids =
--            Dict.toList model.abstractDict
--                |> List.map (\( id, abstr ) -> ( abstr.digest, id ))
--                |> List.filter (\( dig, _ ) -> String.contains (String.toLower key) dig)
--                |> List.map (\( _, id ) -> id)
--    in
--    List.foldl (\id acc -> Dict.get id model.documentDict :: acc) [] ids |> Maybe.Extra.values
