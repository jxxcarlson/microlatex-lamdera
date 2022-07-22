module Backend.Update exposing
    ( applySpecial
    , authorTags
    , createDocument
    , deliverUserMessage
    , fetchDocumentById
    , findDocumentByAuthorAndKey
    , findDocumentByAuthorAndKey_
    , getDocumentByAuthorId
    , getDocumentById
    , getDocumentByPublicId
    , getHomePage
    , getSharedDocuments
    , getUserAndDocumentData
    , getUserData
    , getUserDocuments
    , getUserDocumentsForAuthor
    , getUsersAndOnlineStatus
    , gotAtmosphericRandomNumber
    , hardDeleteDocument
    , hardDeleteDocumentsWithIdList
    , insertDocument
    , join
    , publicTags
    , removeSessionClient
    , removeSessionFromDict
    , saveDocument
    , searchForDocuments
    , searchForDocumentsByAuthorAndKey
    , searchForPublicDocuments
    , signOut
    , unlockDocuments
    , updateAbstracts
    , updateDocumentTags
    )

import Abstract
import Authentication
import Backend.Connection
import Config
import Dict
import Document exposing (Document)
import DocumentTools
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import IncludeFiles
import List.Extra
import Maybe.Extra
import Predicate
import Random
import Share
import Token
import Types exposing (AbstractDict, BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentDict, DocumentHandling(..), MessageStatus(..), ToFrontend(..), UsersDocumentsDict)
import User exposing (User)
import Util


type alias Model =
    BackendModel



-- CHAT


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


applySpecial : BackendModel -> ( BackendModel, Command restriction toMsg BackendMsg )
applySpecial model =
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
    if Predicate.documentIsMineOrIAmAnEditor_ document currentUser then
        let
            updateDoc : Document.Document -> Document.Document
            updateDoc =
                \_ -> { document | modified = model.currentTime }

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
            , Share.narrowCastIfShared model.connectionDict (User.currentUsername currentUser) document
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
        , usersDocumentsDict = usersDocumentsDict
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
                |> List.map (\( a, _ ) -> a)
                |> List.Extra.unique
    in
    List.head usernames



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
        -- userConnections : List ConnectionData
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
            Effect.Lamdera.broadcast (GotUsersWithOnlineStatus (Backend.Connection.getUsersAndOnlineStatus_ model.authenticationDict connectionDict)) :: List.map (\doc -> Share.narrowCast clientId doc connectionDict) documents

        updatedModel =
            setDocumentsToReadOnlyWithUserName username model
    in
    ( { updatedModel
        | sharedDocumentDict = Share.removeUserFromSharedDocumentDict username model.sharedDocumentDict
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
                    Effect.Lamdera.broadcast (GotUsersWithOnlineStatus (Backend.Connection.getUsersAndOnlineStatus_ model.authenticationDict connectionDict)) :: List.map (\doc -> Share.narrowCast clientId doc connectionDict) documents

                updatedModel =
                    setDocumentsToReadOnlyWithUserName username model
            in
            ( { updatedModel
                | sharedDocumentDict = Dict.map Share.removeUserFromSharedDocument model.sharedDocumentDict
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
    ( username, removeSession sessionId clientId data )


removeSession : SessionId -> ClientId -> List ConnectionData -> List ConnectionData
removeSession sessionId clientId list =
    List.filter (\datum -> datum /= { session = sessionId, client = clientId }) list


getUsersAndOnlineStatus : Model -> List ( String, Int )
getUsersAndOnlineStatus model =
    Backend.Connection.getUsersAndOnlineStatus_ model.authenticationDict model.connectionDict


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

        author :: firstKey :: _ ->
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
        |> List.take limit


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


hardDeleteDocumentsWithIdList : List String -> Model -> Model
hardDeleteDocumentsWithIdList ids model =
    List.foldl (\id acc -> hardDeleteDocumentById id acc) model ids


hardDeleteDocumentById : String -> Model -> Model
hardDeleteDocumentById docId model =
    let
        documentDict =
            Dict.remove docId model.documentDict

        publicIdDict =
            Dict.remove docId model.publicIdDict

        abstractDict =
            Dict.remove docId model.abstractDict

        usersDocumentsDict =
            Dict.remove docId model.usersDocumentsDict

        authorIdDict =
            Dict.remove docId model.authorIdDict

        publicDocuments =
            List.filter (\d -> d.id /= docId) model.publicDocuments

        documents =
            List.filter (\d -> d.id /= docId) model.documents
    in
    { model
        | documentDict = documentDict
        , authorIdDict = authorIdDict
        , publicIdDict = publicIdDict
        , abstractDict = abstractDict
        , usersDocumentsDict = usersDocumentsDict
        , publicDocuments = publicDocuments
        , documents = documents
    }


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


numberOfUserDocuments : User -> UsersDocumentsDict -> Int
numberOfUserDocuments user usersDocumentsDict =
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
    List.map (\u -> ( u, numberOfUserDocuments u model.usersDocumentsDict )) userList


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
