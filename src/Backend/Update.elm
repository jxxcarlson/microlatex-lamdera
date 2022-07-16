module Backend.Update exposing
    ( andThenApply
    , apply
    , applySpecial
    , authorTags
    , createDocument
    , createDocumentAtBackend
    , deliverUserMessage
    , fetchDocumentById
    , findDocumentByAuthorAndKey
    , findDocumentByAuthorAndKey_
    , getConnectedUsers
    , getConnectionData
    , getDocumentByAuthorId
    , getDocumentById
    , getDocumentByPublicId
    , getHomePage
    , getMostRecentUserDocuments
    , getSharedDocuments
    , getUserAndDocumentData
    , getUserData
    , getUserDocuments
    , getUserDocumentsForAuthor
    , getUsersAndOnlineStatus
    , getUsersAndOnlineStatus_
    , gotAtmosphericRandomNumber
    , handleChatMsg
    , handlePing
    , hardDeleteDocument
    , insertDocument
    , join
    , publicTags
    , removeSessionClient
    , removeSessionFromDict
    , saveDocument
    , searchForDocuments
    , searchForDocumentsByAuthorAndKey
    , searchForPublicDocuments
    , signIn
    , signOut
    , signUpUser
    , unlockDocuments
    , updateAbstracts
    , updateDocumentTags
    )

import Abstract
import Authentication
import BoundedDeque
import Chat
import Chat.Message
import Cmd.Extra
import Config
import DateTimeUtility
import Deque
import Dict
import Docs
import Document exposing (Document)
import DocumentTools
import Effect.Browser.Dom
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Effect.Time
import Hex
import IncludeFiles
import List.Extra
import Maybe.Extra
import Message
import Parser.Language exposing (Language(..))
import Predicate
import Random
import Set
import Share
import Token
import Types exposing (AbstractDict, BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentDict, DocumentHandling(..), MessageStatus(..), ToFrontend(..), UsersDocumentsDict)
import User exposing (User)
import Util
import View.Utility


type alias Model =
    BackendModel



-- CHAT


handleChatMsg : Chat.Message.ChatMessage -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleChatMsg message model =
    ( { model | chatDict = Chat.Message.insert message model.chatDict }, Command.batch (Chat.narrowCast model message) )


handlePing : Chat.Message.ChatMessage -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handlePing message model =
    let
        groupMembers =
            Dict.get message.group model.chatGroupDict
                |> Maybe.map .members
                |> Maybe.withDefault []
                |> List.filter (\name -> name /= message.sender)

        messages =
            List.map (userMessageFromChatMessage message) groupMembers

        commands : List (Command BackendOnly ToFrontend BackendMsg)
        commands =
            List.map (\m -> deliverUserMessageCmd model m) messages
    in
    ( model, Command.batch commands )


userMessageFromChatMessage : Chat.Message.ChatMessage -> String -> Types.UserMessage
userMessageFromChatMessage { sender, subject, content } recipient =
    { from = sender
    , to = recipient
    , subject = "Ping"
    , content =
        if String.left 2 content == "!!" then
            String.dropLeft 2 content

        else
            content
    , show = []
    , info = ""
    , action = Types.FENoOp
    , actionOnFailureToDeliver = Types.FANoOp
    }


deliverUserMessageCmd : BackendModel -> Types.UserMessage -> Command BackendOnly ToFrontend BackendMsg
deliverUserMessageCmd model usermessage =
    case Dict.get usermessage.to model.connectionDict of
        Nothing ->
            Command.none

        Just connectionData ->
            let
                clientIds =
                    List.map .client connectionData

                commands =
                    List.map (\clientId_ -> Effect.Lamdera.sendToFrontend clientId_ (UserMessageReceived usermessage)) clientIds
            in
            Command.batch commands


deliverUserMessage model clientId usermessage =
    case Dict.get usermessage.to model.connectionDict of
        Nothing ->
            ( model, Effect.Lamdera.sendToFrontend clientId (UndeliverableMessage usermessage) )

        Just connectionData ->
            let
                clientIds =
                    List.map .client connectionData

                commands =
                    List.map (\clientId_ -> Effect.Lamdera.sendToFrontend clientId_ (UserMessageReceived usermessage)) clientIds
            in
            ( model, Command.batch commands )


apply :
    (BackendModel -> ( BackendModel, Command restriction toMsg BackendMsg ))
    -> BackendModel
    -> ( BackendModel, Command restriction toMsg BackendMsg )
apply f model =
    f model


andThenApply :
    (BackendModel -> ( BackendModel, Command restriction toMsg BackendMsg ))
    -> ( BackendModel, Command restriction toMsg BackendMsg )
    -> ( BackendModel, Command restriction toMsg BackendMsg )
andThenApply f ( model, cmd ) =
    let
        ( model2, cmd2 ) =
            f model
    in
    ( model2, Command.batch [ cmd, cmd2 ] )



-- OTHER


setDocumentsToReadOnlyWithUserName : Types.Username -> BackendModel -> BackendModel
setDocumentsToReadOnlyWithUserName username model =
    case Dict.get username model.authenticationDict of
        Nothing ->
            model

        Just { user } ->
            setUsersDocumentsToReadOnly user.id model


setUsersDocumentsToReadOnly : Types.UserId -> BackendModel -> BackendModel
setUsersDocumentsToReadOnly userId model =
    applyToUsersDocuments userId (\doc -> { doc | status = Document.DSReadOnly }) model


{-| Apply a function to all documents for a given user (defined by his user id) and persist the result in the backend model
-}
applyToUsersDocuments : Types.UserId -> (Document -> Document) -> BackendModel -> BackendModel
applyToUsersDocuments userId f model =
    let
        ids =
            Dict.get userId model.usersDocumentsDict |> Maybe.withDefault []
    in
    applyToDocuments (Dict.get userId model.usersDocumentsDict |> Maybe.withDefault []) f model


{-| Apply a function to all documents defined by a list of documents and persist the result in the backend model
-}
applyToDocuments : List Types.DocId -> (Document -> Document) -> BackendModel -> BackendModel
applyToDocuments idList f model =
    let
        oldDocumentDict =
            model.documentDict

        newDocumentDict =
            List.foldl (\id dict -> Dict.update id (Util.liftToMaybe f) dict) oldDocumentDict idList
    in
    { model | documentDict = newDocumentDict }



-- ADMIN


{-| Get pairs (username, number of documents for user)
-}
getUserAndDocumentData : BackendModel -> List ( String, Int )
getUserAndDocumentData model =
    let
        pairs : List ( String, String )
        pairs =
            model.authenticationDict |> Dict.values |> List.map (.user >> (\u -> ( u.username, u.id )))
    in
    List.foldl (\( username, userId ) data -> getUserDocData ( username, userId ) model.usersDocumentsDict :: data) [] pairs


{-| Given (username, userId) return (username, number of user documents)
-}
getUserDocData : ( String, String ) -> Types.UsersDocumentsDict -> ( String, Int )
getUserDocData ( username, userId ) dict =
    ( username, Dict.get userId dict |> Maybe.withDefault [] |> List.length )



-- OTHER


getSharedDocuments model clientId username =
    let
        docList =
            model.sharedDocumentDict
                |> Dict.toList
                |> List.map (\( _, data ) -> ( data.author |> Maybe.withDefault "(anon)", data ))

        connectedUsers =
            getConnectedUsers model

        onlineStatus username_ =
            case Dict.get username_ model.connectionDict of
                Nothing ->
                    False

                Just _ ->
                    True

        docs1 =
            docList
                |> List.filter (\( _, data ) -> Share.isSharedToMe username data.share)
                |> List.map (\( username_, data ) -> ( username_, onlineStatus username_, data ))

        --docs2 =
        --    docList
        --        |> List.filter (\( _, data ) -> data.author == Just username)
        --        |> List.map (\( username_, data ) -> ( username_, onlineStatus username_, data ))
    in
    ( model
    , Effect.Lamdera.sendToFrontend clientId (GotShareDocumentList (docs1 |> List.sortBy (\( _, _, doc ) -> doc.title)))
    )


unlockDocuments : Model -> String -> ( Model, Command restriction toMsg BackendMsg )
unlockDocuments model userId =
    case Dict.get userId model.usersDocumentsDict of
        Nothing ->
            ( model, Command.none )

        Just userDocIds ->
            let
                userDocs =
                    List.map (\id -> Dict.get id model.documentDict) userDocIds
                        |> Maybe.Extra.values
                        |> List.map (\doc -> { doc | currentEditorList = [] })

                newDocumentDict =
                    List.foldl (\doc dict -> Dict.insert doc.id doc dict) model.documentDict userDocs
            in
            ( { model | documentDict = newDocumentDict }, Command.none )


applySpecial : BackendModel -> ClientId -> ( BackendModel, Command restriction toMsg BackendMsg )
applySpecial model clientId =
    let
        updateDoc : Document.Document -> BackendModel -> BackendModel
        updateDoc doc mod =
            let
                updateDoc_ : Document.Document -> Document.Document
                updateDoc_ doc_ =
                    { doc_ | status = Document.DSReadOnly }

                documentDict =
                    Dict.update doc.id (Util.liftToMaybe updateDoc_) mod.documentDict
            in
            { mod | documentDict = documentDict }

        newModel : BackendModel
        newModel =
            List.foldl (\doc m -> updateDoc doc m) model (model.documentDict |> Dict.values)
    in
    ( newModel
    , Command.none
    )


getBadDocuments model =
    model.documentDict |> Dict.toList |> List.filter (\( _, doc ) -> doc.title == "")


getDocumentById model clientId documentHandling id =
    case Dict.get id model.documentDict of
        Nothing ->
            -- ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "No document for that docId", status = MSRed }) )
            ( model, getDocumentByCmdId model clientId id )

        Just doc ->
            ( model
            , Command.batch
                [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocument documentHandling doc)
                , Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "Sending doc " ++ id, status = MSGreen })
                ]
            )


getDocumentByCmdId model clientId id =
    case Dict.get id model.documentDict of
        Nothing ->
            Command.none

        Just doc ->
            Command.batch
                [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocument StandardHandling doc)
                , Effect.Lamdera.sendToFrontend clientId (SetShowEditor False)
                ]


getDocumentByAuthorId model clientId authorId =
    case Dict.get authorId model.authorIdDict of
        Nothing ->
            ( model
            , Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "GetDocumentByAuthorId, No docId for that authorId", status = MSYellow })
            )

        Just docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "No document for that docId", status = MSWhite })
                    )

                Just doc ->
                    ( model
                    , Command.batch
                        [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocument StandardHandling doc)
                        , Effect.Lamdera.sendToFrontend clientId (SetShowEditor True)
                        ]
                    )


getHomePage model clientId username =
    let
        docs =
            -- searchForDocuments_ ("home:" ++ username) model
            searchForDocuments_ (username ++ ":home") model
    in
    case List.head docs of
        Nothing ->
            ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "home page not found", status = MSWhite }) )

        Just doc ->
            ( model
            , Command.batch
                [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocument StandardHandling doc)
                , Effect.Lamdera.sendToFrontend clientId (SetShowEditor False)
                ]
            )


getDocumentByPublicId model clientId publicId =
    case Dict.get publicId model.publicIdDict of
        Nothing ->
            ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "GetDocumentByPublicId, No docId for that publicId", status = MSWhite }) )

        Just docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "No document for that docId", status = MSWhite }) )

                Just doc ->
                    ( model
                    , Command.batch
                        [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocument StandardHandling doc)
                        , Effect.Lamdera.sendToFrontend clientId (SetShowEditor True)
                        ]
                    )


fetchDocumentById model clientId docId documentHandling =
    if String.left 3 docId == "id-" then
        case Dict.get docId model.documentDict of
            Nothing ->
                ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "Couldn't find that document (1)", status = MSWhite }) )

            Just _ ->
                ( model
                , fetchDocumentByIdCmd model clientId docId documentHandling
                )

    else
        ( model
        , fetchDocumentBySlugCmd model clientId docId documentHandling
        )


{-| This command allows one to fetch a doc by its slug
-}
fetchDocumentBySlugCmd : BackendModel -> ClientId -> String -> DocumentHandling -> Command BackendOnly ToFrontend BackendMsg
fetchDocumentBySlugCmd model clientId docSlug documentHandling =
    case Dict.get docSlug model.slugDict of
        Nothing ->
            Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "Couldn't find that document (2)", status = MSWhite })

        Just docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "Couldn't find that document (3)", status = MSWhite })

                Just document ->
                    let
                        filesToInclude : List String
                        filesToInclude =
                            IncludeFiles.getData document.content
                    in
                    Command.batch
                        [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocument documentHandling document)
                        , if List.isEmpty filesToInclude then
                            Command.none

                          else
                            getIncludedFilesCmd model clientId document filesToInclude
                        ]


getIncludedFilesCmd model clientId doc fileList =
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
            findDocumentByAuthorAndKey_ model author (author ++ ":" ++ key)
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
    in
    Effect.Lamdera.sendToFrontend clientId (GotIncludedData doc data)


fetchDocumentByIdCmd : BackendModel -> ClientId -> String -> DocumentHandling -> Command BackendOnly ToFrontend BackendMsg
fetchDocumentByIdCmd model clientId docId documentHandling =
    case Dict.get docId model.documentDict of
        Nothing ->
            Command.none

        Just document ->
            Effect.Lamdera.sendToFrontend clientId (ReceivedDocument documentHandling document)


saveDocument model clientId currentUser document =
    -- TODO: review this for safety
    let
        _ =
            Predicate.documentIsMineOrIAmAnEditor_ document currentUser
    in
    if Predicate.documentIsMineOrIAmAnEditor_ document currentUser then
        let
            updateDoc : Document.Document -> Document.Document
            updateDoc =
                \d -> { document | modified = model.currentTime }

            mUpdateDoc =
                Util.liftToMaybe updateDoc

            updateDocumentDict2 doc dict =
                Dict.update doc.id mUpdateDoc dict

            newSlugDict =
                case getUserTag document of
                    Nothing ->
                        model.slugDict

                    Just userTag ->
                        Dict.insert userTag document.id model.slugDict
        in
        ( { model | documentDict = updateDocumentDict2 document model.documentDict, slugDict = newSlugDict }
        , Command.batch
            [ Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "saved: " ++ String.fromInt (String.length document.content), status = MSGreen })
            , Share.narrowCastIfShared model.connectionDict clientId (Util.currentUsername currentUser) document
            ]
        )

    else
        ( model, Command.none )


getUserTag : Document -> Maybe String
getUserTag doc =
    case doc.author of
        Nothing ->
            Nothing

        Just username ->
            List.filter (\item -> String.contains (username ++ ":") item) doc.tags
                |> List.head



-- { userId : String, username : String, clientId : ClientId }


createDocument model clientId maybeCurrentUser doc_ =
    let
        idTokenData =
            Token.get model.randomSeed

        authorIdTokenData =
            Token.get idTokenData.seed

        publicIdTokenData =
            Token.get authorIdTokenData.seed

        humanFriendlyPublicId =
            case maybeCurrentUser of
                Nothing ->
                    publicIdTokenData.token

                Just user ->
                    -- TODO: revisit this
                    user.username ++ "-" ++ String.slice 1 2 publicIdTokenData.token

        doc =
            { doc_
                | id = "id-" ++ idTokenData.token
                , publicId = humanFriendlyPublicId
                , created = model.currentTime
                , modified = model.currentTime
            }

        documentDict =
            Dict.insert ("id-" ++ idTokenData.token) doc model.documentDict

        authorIdDict =
            Dict.insert ("au-" ++ authorIdTokenData.token) doc.id model.authorIdDict

        publicIdDict =
            Dict.insert humanFriendlyPublicId doc.id model.publicIdDict

        usersDocumentsDict =
            case maybeCurrentUser of
                Nothing ->
                    model.usersDocumentsDict

                Just user ->
                    let
                        oldIdList =
                            Dict.get user.id model.usersDocumentsDict |> Maybe.withDefault []
                    in
                    Dict.insert user.id (doc.id :: oldIdList) model.usersDocumentsDict
    in
    ( { model
        | randomSeed = publicIdTokenData.seed
        , documentDict = documentDict
        , authorIdDict = authorIdDict
        , publicIdDict = publicIdDict
        , usersDocumentsDict = usersDocumentsDict
      }
    , Effect.Lamdera.sendToFrontend clientId (ReceivedNewDocument StandardHandling doc)
    )


createDocumentAtBackend : Maybe User -> Document -> Model -> Model
createDocumentAtBackend maybeCurrentUser doc_ model =
    let
        idTokenData =
            Token.get model.randomSeed

        authorIdTokenData =
            Token.get idTokenData.seed

        doc =
            { doc_
                | id = "id-" ++ idTokenData.token
                , created = model.currentTime
                , modified = model.currentTime
            }

        documentDict =
            Dict.insert ("id-" ++ idTokenData.token) doc model.documentDict

        authorIdDict =
            Dict.insert ("au-" ++ authorIdTokenData.token) doc.id model.authorIdDict

        usersDocumentsDict =
            case maybeCurrentUser of
                Nothing ->
                    model.usersDocumentsDict

                Just user ->
                    let
                        oldIdList =
                            Dict.get user.id model.usersDocumentsDict |> Maybe.withDefault []
                    in
                    Dict.insert user.id (doc.id :: oldIdList) model.usersDocumentsDict
    in
    { model
        | randomSeed = authorIdTokenData.seed
        , documentDict = documentDict
        , authorIdDict = authorIdDict
        , usersDocumentsDict = usersDocumentsDict
    }


insertDocument model clientId user doc_ =
    let
        doc =
            { doc_ | created = model.currentTime, modified = model.currentTime }

        documentDict =
            Dict.insert doc.id doc model.documentDict

        authorIdDict =
            Dict.insert (doc.id ++ "-bak") doc.id model.authorIdDict

        usersDocumentsDict =
            let
                oldIdList =
                    Dict.get user.id model.usersDocumentsDict |> Maybe.withDefault []
            in
            Dict.insert user.id ((doc.id ++ "-bak") :: oldIdList) model.usersDocumentsDict
    in
    ( { model
        | documentDict = documentDict
        , authorIdDict = authorIdDict

        --, usersDocumentsDict = usersDocumentsDict
      }
    , Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "Backup made for " ++ String.replace "(BAK)" "" doc.title ++ " (" ++ String.fromInt (String.length doc.content) ++ " chars)", status = MSYellow })
    )


getConnectedUser : ClientId -> ConnectionDict -> Maybe Types.Username
getConnectedUser clientId dict =
    let
        connectionData =
            dict |> Dict.toList |> List.map (\( username, data ) -> ( username, List.map .client data ))

        usernames =
            connectionData
                |> List.filter (\( _, data ) -> List.member clientId data)
                |> List.map (\( a, b ) -> a)
                |> List.Extra.unique
    in
    List.head usernames


resetCurrentEditorForUser : Types.Username -> Types.SharedDocumentDict -> Types.SharedDocumentDict
resetCurrentEditorForUser username dict =
    Dict.map (\user shareDocInfo -> Share.resetDocument username shareDocInfo) dict



--cleanup model sessionId clientId =
--    ( { model
--        | connectionDict = Dict.empty
--        , editEvents = Deque.empty
--        , sharedDocumentDict = Share.removeConnectionFromSharedDocumentDict clientId model.sharedDocumentDict
--      }
--    , Cmd.none
--    )


{-|

        This function differs from  removeSessionClient only in (a) it does not use the sessionId,
        (b) it treats the connectionDict more gingerely.

-}
signOut : BackendModel -> Types.Username -> ClientId -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
signOut model username clientId =
    let
        userConnections : List ConnectionData
        userConnections =
            Dict.get username model.connectionDict |> Maybe.withDefault []

        connectionDict =
            Dict.remove username model.connectionDict

        activeSharedDocIds =
            Share.activeDocumentIdsSharedByMe username model.sharedDocumentDict |> List.map .id

        documents : List Document.Document
        documents =
            List.foldl (\id list -> Dict.get id model.documentDict :: list) [] activeSharedDocIds
                |> Maybe.Extra.values
                |> List.map (\doc -> Share.unshare doc)

        pushSignOutDocCmd : Command BackendOnly ToFrontend BackendMsg
        pushSignOutDocCmd =
            fetchDocumentByIdCmd model clientId Config.signOutDocumentId StandardHandling

        notifications =
            Effect.Lamdera.broadcast (GotUsersWithOnlineStatus (getUsersAndOnlineStatus_ model.authenticationDict connectionDict)) :: List.map (\doc -> Share.narrowCast clientId doc connectionDict) documents

        updatedModel =
            setDocumentsToReadOnlyWithUserName username model
    in
    ( { updatedModel
        | sharedDocumentDict = Dict.map Share.resetDocument model.sharedDocumentDict
        , connectionDict = connectionDict
      }
    , Command.batch <| pushSignOutDocCmd :: notifications
    )


removeSessionClient : BackendModel -> SessionId -> ClientId -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
removeSessionClient model sessionId clientId =
    case getConnectedUser clientId model.connectionDict of
        Nothing ->
            ( { model | connectionDict = removeSessionFromDict sessionId clientId model.connectionDict }, Command.none )

        Just username ->
            let
                connectionDict =
                    removeSessionFromDict sessionId clientId model.connectionDict

                activeSharedDocIds =
                    Share.activeDocumentIdsSharedByMe username model.sharedDocumentDict |> List.map .id

                documents : List Document.Document
                documents =
                    List.foldl (\id list -> Dict.get id model.documentDict :: list) [] activeSharedDocIds
                        |> Maybe.Extra.values
                        |> List.map (\doc -> Share.unshare doc)

                pushSignOutDocCmd : Command BackendOnly ToFrontend BackendMsg
                pushSignOutDocCmd =
                    fetchDocumentByIdCmd model clientId Config.signOutDocumentId StandardHandling

                notifications =
                    Effect.Lamdera.broadcast (GotUsersWithOnlineStatus (getUsersAndOnlineStatus_ model.authenticationDict connectionDict)) :: List.map (\doc -> Share.narrowCast clientId doc connectionDict) documents

                updatedModel =
                    setDocumentsToReadOnlyWithUserName username model
            in
            ( { updatedModel
                | sharedDocumentDict = Dict.map Share.resetDocument model.sharedDocumentDict
                , connectionDict = connectionDict
              }
            , Command.batch <| pushSignOutDocCmd :: notifications
            )


removeSessionFromDict : SessionId -> ClientId -> ConnectionDict -> ConnectionDict
removeSessionFromDict sessionId clientId connectionDict =
    connectionDict
        |> Dict.toList
        |> removeSessionFromList sessionId clientId
        |> Dict.fromList


removeSessionFromList : SessionId -> ClientId -> List ( String, List ConnectionData ) -> List ( String, List ConnectionData )
removeSessionFromList sessionId clientId dataList =
    List.map (\item -> removeItem sessionId clientId item) dataList
        |> List.filter (\( _, list ) -> list /= [])


removeItem : SessionId -> ClientId -> ( String, List ConnectionData ) -> ( String, List ConnectionData )
removeItem sessionId clientId ( username, data ) =
    ( username, removeSession username sessionId clientId data )


removeSession : String -> SessionId -> ClientId -> List ConnectionData -> List ConnectionData
removeSession username sessionId clientId list =
    List.filter (\datum -> datum /= { session = sessionId, client = clientId }) list


signIn model sessionId clientId username encryptedPassword =
    case Dict.get username model.authenticationDict of
        Just userData ->
            if Authentication.verify username encryptedPassword model.authenticationDict then
                let
                    newConnectionDict_ =
                        newConnectionDict username sessionId clientId model.connectionDict

                    chatGroup =
                        case userData.user.preferences.group of
                            Nothing ->
                                Nothing

                            Just groupName ->
                                Dict.get groupName model.chatGroupDict

                    newsDoc =
                        Dict.get Config.newsDocId model.documentDict |> Maybe.withDefault Document.empty

                    docs =
                        List.filter (\d -> d.id /= Config.newsDocId) (getMostRecentUserDocuments Types.SortByMostRecent Config.maxDocSearchLimit userData.user model.usersDocumentsDict model.documentDict)
                in
                ( { model | connectionDict = newConnectionDict_ }
                , Command.batch
                    [ -- TODO: restore the belo
                      Effect.Lamdera.sendToFrontend clientId (ReceivedDocuments StandardHandling <| (newsDoc :: docs))

                    --, sendToFrontend clientId (ReceivedPublicDocuments (searchForPublicDocuments Types.SortAlphabetically Config.maxDocSearchLimit (Just userData.user.username) "system:startup" model))
                    , Effect.Lamdera.sendToFrontend clientId (UserSignedUp userData.user clientId)
                    , Effect.Lamdera.sendToFrontend clientId (MessageReceived <| { txt = "Signed in as " ++ userData.user.username, status = MSGreen })
                    , Effect.Lamdera.sendToFrontend clientId (GotChatGroup chatGroup)
                    , Effect.Lamdera.broadcast (GotUsersWithOnlineStatus (getUsersAndOnlineStatus_ model.authenticationDict newConnectionDict_))
                    ]
                )

            else
                ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived <| { txt = "Sorry, password and username don't match", status = MSRed }) )

        Nothing ->
            ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived <| { txt = "Sorry, password and username don't match", status = MSRed }) )


type alias UserData =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Effect.Time.Posix
    , modified : Effect.Time.Posix
    , docs : BoundedDeque.BoundedDeque Document.DocumentInfo
    , preferences : User.Preferences
    }


getUsersAndOnlineStatus : Model -> List ( String, Int )
getUsersAndOnlineStatus model =
    getUsersAndOnlineStatus_ model.authenticationDict model.connectionDict


getUsersAndOnlineStatus_ : Authentication.AuthenticationDict -> ConnectionDict -> List ( String, Int )
getUsersAndOnlineStatus_ authenticationDict connectionDict =
    let
        isConnected username =
            case Dict.get username connectionDict of
                Nothing ->
                    0

                Just data ->
                    List.length data
    in
    List.map (\u -> ( u, isConnected u )) (Dict.keys authenticationDict)


searchForDocuments : Model -> ClientId -> DocumentHandling -> Maybe User -> String -> ( Model, Command BackendOnly ToFrontend backendMsg )
searchForDocuments model clientId documentHandling currentUser key =
    ( model
    , if String.contains ":user" key then
        Effect.Lamdera.sendToFrontend clientId (ReceivedDocuments documentHandling (searchForUserDocuments (Maybe.map .username currentUser) (stripKey ":user" key) model))

      else
        Command.batch
            [ Effect.Lamdera.sendToFrontend clientId (ReceivedDocuments documentHandling (searchForUserDocuments (Maybe.map .username currentUser) key model))
            , Effect.Lamdera.sendToFrontend clientId (ReceivedPublicDocuments (searchForPublicDocuments Types.SortAlphabetically Config.maxDocSearchLimit (Maybe.map .username currentUser) key model))
            ]
    )


stripKey str key =
    String.replace str key "" |> String.trim


searchForDocumentsByAuthorAndKey model clientId key =
    ( model, Effect.Lamdera.sendToFrontend clientId (ReceivedDocuments StandardHandling (searchForDocumentsByAuthorAndKey_ model key)) )


searchForDocumentsByAuthorAndKey_ : Model -> String -> List Document.Document
searchForDocumentsByAuthorAndKey_ model key =
    case String.split "/" key of
        [] ->
            []

        author :: [] ->
            getUserDocumentsForAuthor author model

        author :: firstKey :: rest ->
            getUserDocumentsForAuthor author model |> List.filter (\doc -> List.member ("id:" ++ firstKey) doc.tags)


findDocumentByAuthorAndKey : BackendModel -> ClientId -> Types.DocumentHandling -> String -> String -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
findDocumentByAuthorAndKey model clientId documentHandling authorName searchKey =
    case findDocumentByAuthorAndKey_ model authorName searchKey of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            ( model, Effect.Lamdera.sendToFrontend clientId (ReceivedDocument documentHandling doc) )


findDocumentByAuthorAndKey_ : BackendModel -> String -> String -> Maybe Document
findDocumentByAuthorAndKey_ model authorName searchKey =
    let
        foundDocs =
            getUserDocumentsForAuthor authorName model |> List.filter (\doc -> List.member searchKey doc.tags)
    in
    List.head foundDocs


getUserDocumentsForAuthor : String -> Model -> List Document.Document
getUserDocumentsForAuthor author model =
    case Authentication.userIdFromUserName author model.authenticationDict of
        Nothing ->
            []

        Just userId ->
            case Dict.get userId model.usersDocumentsDict of
                Nothing ->
                    []

                Just usersDocIds ->
                    List.map (\id -> Dict.get id model.documentDict) usersDocIds |> Maybe.Extra.values



-- TAGS


authorTags : String -> Model -> Dict.Dict String (List { id : String, title : String })
authorTags authorName model =
    makeTagDict (getUserDocumentsForAuthor authorName model |> List.filter (\{ title } -> not (String.contains "(BAK)" title)))


publicTags : Model -> Dict.Dict String (List { id : String, title : String })
publicTags model =
    let
        publicDocs =
            model.documentDict
                |> Dict.toList
                |> List.map (\( _, doc ) -> doc)
                |> List.filter (\doc -> doc.public)
                |> List.filter (\{ title } -> not (String.contains "(BAK)" title))
    in
    makeTagDict publicDocs


tagsOfDocList : List Document.Document -> List { id : String, title : String, tags : List String }
tagsOfDocList docs =
    List.map (\doc -> { id = doc.id, title = doc.title, tags = doc.tags }) docs


makeTagDict : List Document.Document -> Dict.Dict String (List { id : String, title : String })
makeTagDict docs =
    docs
        |> tagsOfDocList
        |> unroll
        |> List.foldl insertIf Dict.empty


unroll_ : { id : String, title : String, tags : List String } -> List { id : String, title : String, tag : String }
unroll_ { id, title, tags } =
    List.map (\tag -> { id = id, title = title, tag = fixIfHomeTag tag }) tags


unroll : List { id : String, title : String, tags : List String } -> List { id : String, title : String, tag : String }
unroll list =
    List.map unroll_ list |> List.concat


fixIfHomeTag : String -> String
fixIfHomeTag str =
    if String.left 5 str == "home:" then
        "home"

    else
        str


insertIf : { a | id : b, title : c, tag : String } -> Dict.Dict String (List { id : b, title : c }) -> Dict.Dict String (List { id : b, title : c })
insertIf { id, title, tag } dict =
    if tag == "" then
        dict

    else
        case Dict.get tag dict of
            Nothing ->
                Dict.insert tag [ { id = id, title = title } ] dict

            Just ids ->
                Dict.insert tag ({ id = id, title = title } :: ids) dict


searchForPublicDocuments : Types.SortMode -> Int -> Maybe String -> String -> Model -> List Document.Document
searchForPublicDocuments sortMode limit mUsername key model =
    searchForDocuments_ key model
        |> List.filter (\doc -> doc.public || Predicate.isSharedToMe_ mUsername doc)
        |> DocumentTools.sort sortMode
        |> List.take Config.maxDocSearchLimit


searchForDocuments_ : String -> Model -> List Document.Document
searchForDocuments_ key model =
    let
        ids =
            Dict.toList model.abstractDict
                |> List.map (\( id, abstr ) -> ( abstr.digest, id ))
                |> List.filter (\( dig, _ ) -> String.contains (String.toLower key) dig)
                |> List.map (\( _, id ) -> id)
    in
    List.foldl (\id acc -> Dict.get id model.documentDict :: acc) [] ids |> Maybe.Extra.values


searchForUserDocuments : Maybe String -> String -> Model -> List Document.Document
searchForUserDocuments maybeUsername key model =
    let
        ids =
            Dict.toList model.abstractDict
                |> List.map (\( id, abstr ) -> ( abstr.digest, id ))
                |> List.filter (\( dig, _ ) -> String.contains (String.toLower key) dig)
                |> List.map (\( _, id ) -> id)
    in
    List.foldl (\id acc -> Dict.get id model.documentDict :: acc) [] ids
        |> Maybe.Extra.values
        |> List.filter (\doc -> doc.author /= Just "" && doc.author == maybeUsername)
        |> List.take Config.maxDocSearchLimit



-- SYSTEM


hardDeleteDocument : ClientId -> Document.Document -> Model -> ( Model, Command BackendOnly ToFrontend msg )
hardDeleteDocument clientId doc model =
    let
        documentDict =
            Dict.remove doc.id model.documentDict

        publicIdDict =
            Dict.remove doc.id model.publicIdDict

        abstractDict =
            Dict.remove doc.id model.abstractDict

        usersDocumentsDict =
            Dict.remove doc.id model.usersDocumentsDict

        authorIdDict =
            Dict.remove doc.id model.authorIdDict

        publicDocuments =
            List.filter (\d -> d.id /= doc.id) model.publicDocuments

        documents =
            List.filter (\d -> d.id /= doc.id) model.documents
    in
    ( { model
        | documentDict = documentDict
        , authorIdDict = authorIdDict
        , publicIdDict = publicIdDict
        , abstractDict = abstractDict
        , usersDocumentsDict = usersDocumentsDict
        , publicDocuments = publicDocuments
        , documents = documents
      }
    , getDocumentByCmdId model clientId Config.documentDeletedNotice
    )


gotAtmosphericRandomNumber : Model -> Result error String -> ( Model, Command BackendOnly ToFrontend msg )
gotAtmosphericRandomNumber model result =
    case result of
        Ok str ->
            case String.toInt (String.trim str) of
                Nothing ->
                    ( model, Effect.Lamdera.broadcast (MessageReceived { txt = "Could not get atomospheric integer", status = MSWhite }) )

                Just rn ->
                    let
                        newRandomSeed =
                            Random.initialSeed rn
                    in
                    ( { model
                        | randomAtmosphericInt = Just rn
                        , randomSeed = newRandomSeed
                      }
                    , Effect.Lamdera.broadcast (MessageReceived { txt = "Got atmospheric integer " ++ String.fromInt rn, status = MSWhite })
                    )

        Err _ ->
            ( model, Command.none )



-- USER


newConnectionDict username sessionId clientId connectionDict =
    case Dict.get username connectionDict of
        Nothing ->
            Dict.insert username [ { session = sessionId, client = clientId } ] connectionDict

        Just [] ->
            Dict.insert username [ { session = sessionId, client = clientId } ] connectionDict

        Just connections ->
            Dict.insert username ({ session = sessionId, client = clientId } :: connections) connectionDict


signUpUser : Model -> SessionId -> ClientId -> String -> Language -> String -> String -> String -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
signUpUser model sessionId clientId username lang transitPassword realname email =
    let
        newConnectionDict_ =
            newConnectionDict username sessionId clientId model.connectionDict

        ( randInt, seed ) =
            Random.step (Random.int (Random.minInt // 2) (Random.maxInt - 1000)) model.randomSeed

        randomHex =
            Hex.toString randInt |> String.toUpper

        tokenData =
            Token.get seed

        user =
            { username = username
            , id = tokenData.token
            , realname = realname
            , email = email
            , created = model.currentTime
            , modified = model.currentTime
            , docs = BoundedDeque.empty 15
            , preferences = { language = lang, group = Nothing }
            , chatGroups = []
            , sharedDocuments = []
            , sharedDocumentAuthors = Set.empty
            , pings = []
            }

        deletedDocsFolder_ =
            Docs.deletedDocsFolder username
    in
    case Authentication.insert user randomHex transitPassword model.authenticationDict of
        Err str ->
            ( { model | randomSeed = tokenData.seed }, Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "Error: " ++ str, status = MSRed }) )

        Ok authDict ->
            ( { model
                | connectionDict = newConnectionDict_
                , randomSeed = tokenData.seed
                , authenticationDict = authDict
                , usersDocumentsDict = Dict.insert user.id [] model.usersDocumentsDict
              }
                |> createDocumentAtBackend (Just user) deletedDocsFolder_
            , Command.batch
                [ Effect.Lamdera.sendToFrontend clientId (UserSignedUp user clientId)
                , Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "Success! Your account is set up.", status = MSGreen })
                ]
            )


getUserDocuments : Types.SortMode -> Int -> User -> UsersDocumentsDict -> DocumentDict -> List Document.Document
getUserDocuments sortMode limit user usersDocumentsDict documentDict =
    case Dict.get user.id usersDocumentsDict of
        Nothing ->
            []

        Just docIds ->
            List.foldl (\id acc -> Dict.get id documentDict :: acc) [] docIds
                |> Maybe.Extra.values
                |> DocumentTools.sort sortMode
                |> List.take limit


getMostRecentUserDocuments : Types.SortMode -> Int -> User -> UsersDocumentsDict -> DocumentDict -> List Document.Document
getMostRecentUserDocuments sortMode limit user usersDocumentsDict documentDict =
    case Dict.get user.id usersDocumentsDict of
        Nothing ->
            []

        Just docIds ->
            List.foldl (\id acc -> Dict.get id documentDict :: acc) [] docIds
                |> Maybe.Extra.values
                |> DocumentTools.sort Types.SortByMostRecent
                |> List.take limit
                |> DocumentTools.sort sortMode


numberOfUserDocuments : User -> UsersDocumentsDict -> DocumentDict -> Int
numberOfUserDocuments user usersDocumentsDict documentDict =
    case Dict.get user.id usersDocumentsDict of
        Nothing ->
            0

        Just docIds ->
            List.length docIds


getUserData : BackendModel -> List ( User, Int )
getUserData model =
    let
        userList : List User
        userList =
            Authentication.userList model.authenticationDict
    in
    List.map (\u -> ( u, numberOfUserDocuments u model.usersDocumentsDict model.documentDict )) userList


getConnectionData : BackendModel -> List String
getConnectionData model =
    model.connectionDict
        |> Dict.toList
        |> List.map (\( u, data ) -> u ++ ":: " ++ String.fromInt (List.length data) ++ " :: " ++ connectionDataListToString data)


{-| Return user names of connected users
-}
getConnectedUsers : BackendModel -> List String
getConnectedUsers model =
    Dict.keys model.connectionDict


truncateMiddle : Int -> Int -> String -> String
truncateMiddle dropBoth dropRight str =
    String.left dropBoth str ++ "..." ++ String.right dropBoth (String.dropRight dropRight str)


connectionDataListToString : List ConnectionData -> String
connectionDataListToString list =
    list |> List.map connectionDataToString |> String.join "; "


connectionDataToString : ConnectionData -> String
connectionDataToString { session, client } =
    "(" ++ truncateMiddle 2 0 (Effect.Lamdera.sessionIdToString session) ++ ", " ++ truncateMiddle 2 2 (Effect.Lamdera.clientIdToString client) ++ ")"


updateAbstract : Document.Document -> AbstractDict -> AbstractDict
updateAbstract doc dict =
    Dict.insert doc.id (Abstract.get doc.author doc.language doc.content) dict


updateAbstractById : String -> DocumentDict -> AbstractDict -> AbstractDict
updateAbstractById id docDict abstractDict =
    case Dict.get id docDict of
        Nothing ->
            abstractDict

        Just doc ->
            updateAbstract doc abstractDict


updateAbstracts : DocumentDict -> AbstractDict -> AbstractDict
updateAbstracts documentDict abstractDict =
    List.foldl (\id acc -> updateAbstractById id documentDict acc) abstractDict (Dict.keys documentDict)


updateDocumentTagsInDict : DocumentDict -> DocumentDict
updateDocumentTagsInDict dict =
    List.foldl (\doc dict_ -> Dict.insert doc.id (Document.setTags doc) dict_) dict (Dict.values dict)


updateDocumentTags : Model -> Model
updateDocumentTags model =
    { model | documentDict = updateDocumentTagsInDict model.documentDict }


join :
    (BackendModel -> ( BackendModel, Command restriction toMsg BackendMsg ))
    -> (BackendModel -> ( BackendModel, Command restriction toMsg BackendMsg ))
    -> (BackendModel -> ( BackendModel, Command restriction toMsg BackendMsg ))
join f g =
    \m ->
        let
            ( m1, cmd1 ) =
                f m

            ( m2, cmd2 ) =
                g m1
        in
        ( m2, Command.batch [ cmd1, cmd2 ] )
