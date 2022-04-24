module Backend.Update exposing
    ( applySpecial
    , authorTags
    , createDocument
    , fetchDocumentById
    , findDocumentByAuthorAndKey
    , getConnectedUsers
    , getConnectionData
    , getDocumentByAuthorId
    , getDocumentById
    , getDocumentByPublicId
    , getHomePage
    , getSharedDocuments
    , getUserAndDocumentData
    , getUserData
    , getUserDocuments
    , getUsersAndOnlineStatus
    , getUsersAndOnlineStatus_
    , gotAtmosphericRandomNumber
    , hardDeleteDocument
    , insertDocument
    , publicTags
    , removeSessionClient
    , removeSessionFromDict
    , saveDocument
    , searchForDocuments
    , searchForDocumentsByAuthorAndKey
    , searchForPublicDocuments
    , signIn
    , signUpUser
    , unlockDocuments
    , updateAbstracts
    , updateDocumentTags
    )

import Abstract
import Authentication
import BoundedDeque
import Cmd.Extra
import Config
import DateTimeUtility
import Dict
import Document exposing (Document)
import DocumentTools
import Hex
import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import List.Extra
import Maybe.Extra
import Message
import Parser.Language exposing (Language(..))
import Predicate
import Random
import Set
import Share
import Time
import Token
import Types exposing (AbstractDict, BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentDict, DocumentHandling(..), MessageStatus(..), ToFrontend(..), UsersDocumentsDict)
import User exposing (User)
import Util
import View.Utility


type alias Model =
    BackendModel


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

        docs2 =
            docList
                |> List.filter (\( _, data ) -> data.author == Just username)
                |> List.map (\( username_, data ) -> ( username_, onlineStatus username_, data ))
    in
    ( model
    , sendToFrontend clientId (GotShareDocumentList (docs1 ++ docs2 |> List.sortBy (\( _, _, doc ) -> doc.title)))
    )


unlockDocuments : Model -> String -> ( Model, Cmd BackendMsg )
unlockDocuments model userId =
    case Dict.get userId model.usersDocumentsDict of
        Nothing ->
            ( model, Cmd.none )

        Just userDocIds ->
            let
                userDocs =
                    List.map (\id -> Dict.get id model.documentDict) userDocIds
                        |> Maybe.Extra.values
                        |> List.map (\doc -> { doc | currentEditor = Nothing })

                newDocumentDict =
                    List.foldl (\doc dict -> Dict.insert doc.id doc dict) model.documentDict userDocs
            in
            ( { model | documentDict = newDocumentDict }, Cmd.none )


applySpecial : BackendModel -> ClientId -> ( BackendModel, Cmd BackendMsg )
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
    , Cmd.none
    )


getBadDocuments model =
    model.documentDict |> Dict.toList |> List.filter (\( _, doc ) -> doc.title == "")


getDocumentById model clientId documentHandling id =
    case Dict.get id model.documentDict of
        Nothing ->
            ( model, sendToFrontend clientId (MessageReceived { txt = "No document for that docId", status = MSRed }) )

        Just doc ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId (ReceivedDocument documentHandling doc)

                --, sendToFrontend clientId (SetShowEditor False)
                , sendToFrontend clientId (MessageReceived { txt = "Sending doc " ++ id, status = MSGreen })
                ]
            )


getDocumentByCmdId model clientId id =
    case Dict.get id model.documentDict of
        Nothing ->
            Cmd.none

        Just doc ->
            Cmd.batch
                [ sendToFrontend clientId (ReceivedDocument StandardHandling doc)
                , sendToFrontend clientId (SetShowEditor False)
                ]


getDocumentByAuthorId model clientId authorId =
    case Dict.get authorId model.authorIdDict of
        Nothing ->
            ( model
            , sendToFrontend clientId (MessageReceived { txt = "GetDocumentByAuthorId, No docId for that authorId", status = MSYellow })
            )

        Just docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model
                    , sendToFrontend clientId (MessageReceived { txt = "No document for that docId", status = MSWhite })
                    )

                Just doc ->
                    ( model
                    , Cmd.batch
                        [ sendToFrontend clientId (ReceivedDocument StandardHandling doc)
                        , sendToFrontend clientId (SetShowEditor True)
                        ]
                    )


getHomePage model clientId username =
    let
        docs =
            searchForDocuments_ ("home:" ++ username) model
    in
    case List.head docs of
        Nothing ->
            ( model, sendToFrontend clientId (MessageReceived { txt = "home page not found", status = MSWhite }) )

        Just doc ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId (ReceivedDocument StandardHandling doc)
                , sendToFrontend clientId (SetShowEditor False)
                ]
            )


getDocumentByPublicId model clientId publicId =
    case Dict.get publicId model.publicIdDict of
        Nothing ->
            ( model, sendToFrontend clientId (MessageReceived { txt = "GetDocumentByPublicId, No docId for that publicId", status = MSWhite }) )

        Just docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model, sendToFrontend clientId (MessageReceived { txt = "No document for that docId", status = MSWhite }) )

                Just doc ->
                    ( model
                    , Cmd.batch
                        [ sendToFrontend clientId (ReceivedDocument StandardHandling doc)
                        , sendToFrontend clientId (SetShowEditor True)
                        ]
                    )


fetchDocumentById model clientId docId documentHandling =
    case Dict.get docId model.documentDict of
        Nothing ->
            ( model, sendToFrontend clientId (MessageReceived { txt = "Couldn't find that document", status = MSWhite }) )

        Just document ->
            ( model
            , fetchDocumentByIdCmd model clientId docId documentHandling
            )


fetchDocumentByIdCmd : BackendModel -> ClientId -> String -> DocumentHandling -> Cmd BackendMsg
fetchDocumentByIdCmd model clientId docId documentHandling =
    case Dict.get docId model.documentDict of
        Nothing ->
            Cmd.none

        Just document ->
            sendToFrontend clientId (ReceivedDocument documentHandling document)


saveDocument model clientId document =
    -- TODO: review this for safety
    let
        updateDoc : Document.Document -> Document.Document
        updateDoc =
            \d -> { document | modified = model.currentTime }

        mUpdateDoc =
            Util.liftToMaybe updateDoc

        updateDocumentDict2 doc dict =
            Dict.update doc.id mUpdateDoc dict
    in
    ( { model | documentDict = updateDocumentDict2 document model.documentDict }, sendToFrontend clientId (MessageReceived { txt = "saved: " ++ String.fromInt (String.length document.content), status = MSGreen }) )


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
    { model
        | randomSeed = publicIdTokenData.seed
        , documentDict = documentDict
        , authorIdDict = authorIdDict
        , publicIdDict = publicIdDict
        , usersDocumentsDict = usersDocumentsDict
    }
        |> Cmd.Extra.withCmds
            [ sendToFrontend clientId (ReceivedNewDocument StandardHandling doc)
            ]


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
    , sendToFrontend clientId (MessageReceived { txt = "Backup made for " ++ String.replace "(BAK)" "" doc.title ++ " (" ++ String.fromInt (String.length doc.content) ++ " chars)", status = MSYellow })
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
    Dict.map (\user shareDocInfo -> Share.resetUser username shareDocInfo) dict


removeSessionClient model sessionId clientId =
    case getConnectedUser clientId model.connectionDict of
        Nothing ->
            ( { model | connectionDict = removeSessionFromDict sessionId clientId model.connectionDict }, Cmd.none )

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

                pushSignOutDocCmd : Cmd BackendMsg
                pushSignOutDocCmd =
                    fetchDocumentByIdCmd model clientId Config.signOutDocumentId StandardHandling

                notifications =
                    broadcast (GotUsersWithOnlineStatus (getUsersAndOnlineStatus_ model.authenticationDict connectionDict)) :: List.map (\doc -> Share.narrowCast username doc connectionDict) documents

                updatedModel =
                    setDocumentsToReadOnlyWithUserName username model
            in
            ( { updatedModel
                | sharedDocumentDict = Dict.map Share.resetUser model.sharedDocumentDict
                , connectionDict = connectionDict
              }
            , Cmd.batch <| pushSignOutDocCmd :: notifications
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
                in
                ( { model | connectionDict = newConnectionDict_ }
                , Cmd.batch
                    [ -- TODO: restore the below
                      sendToFrontend clientId (ReceivedDocuments StandardHandling <| getMostRecentUserDocuments Types.SortAlphabetically Config.maxDocSearchLimit userData.user model.usersDocumentsDict model.documentDict)

                    --, sendToFrontend clientId (ReceivedPublicDocuments (searchForPublicDocuments Types.SortAlphabetically Config.maxDocSearchLimit (Just userData.user.username) "system:startup" model))
                    , sendToFrontend clientId (UserSignedUp userData.user)
                    , sendToFrontend clientId (MessageReceived <| { txt = "Signed in as " ++ userData.user.username, status = MSGreen })
                    , sendToFrontend clientId (GotChatGroup chatGroup)
                    , broadcast (GotUsersWithOnlineStatus (getUsersAndOnlineStatus_ model.authenticationDict newConnectionDict_))
                    ]
                )

            else
                ( model, sendToFrontend clientId (MessageReceived <| { txt = "Sorry, password and username don't match", status = MSRed }) )

        Nothing ->
            ( model, sendToFrontend clientId (MessageReceived <| { txt = "Sorry, password and username don't match", status = MSRed }) )


type alias UserData =
    { username : String
    , id : String
    , realname : String
    , email : String
    , created : Time.Posix
    , modified : Time.Posix
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


searchForDocuments : Model -> ClientId -> DocumentHandling -> Maybe String -> String -> ( Model, Cmd backendMsg )
searchForDocuments model clientId documentHandling maybeUsername key =
    ( model
    , if String.contains ":user" key then
        sendToFrontend clientId (ReceivedDocuments documentHandling (searchForUserDocuments maybeUsername (stripKey ":user" key) model))

      else
        Cmd.batch
            [ sendToFrontend clientId (ReceivedDocuments documentHandling (searchForUserDocuments maybeUsername key model))
            , sendToFrontend clientId (ReceivedPublicDocuments (searchForPublicDocuments Types.SortAlphabetically Config.maxDocSearchLimit maybeUsername key model))
            ]
    )


stripKey str key =
    String.replace str key "" |> String.trim


searchForDocumentsByAuthorAndKey model clientId key =
    ( model, sendToFrontend clientId (ReceivedDocuments StandardHandling (searchForDocumentsByAuthorAndKey_ model clientId key)) )


searchForDocumentsByAuthorAndKey_ : Model -> ClientId -> String -> List Document.Document
searchForDocumentsByAuthorAndKey_ model clientId key =
    case String.split "/" key of
        [] ->
            []

        author :: [] ->
            getUserDocumentsForAuthor author model

        author :: firstKey :: rest ->
            getUserDocumentsForAuthor author model |> List.filter (\doc -> List.member ("id:" ++ firstKey) doc.tags)


findDocumentByAuthorAndKey : BackendModel -> ClientId -> Types.DocumentHandling -> String -> String -> ( BackendModel, Cmd BackendMsg )
findDocumentByAuthorAndKey model clientId documentHandling authorName searchKey =
    let
        foundDocs =
            getUserDocumentsForAuthor authorName model |> List.filter (\doc -> List.member searchKey doc.tags)
    in
    case List.head foundDocs of
        Nothing ->
            ( model, Cmd.none )

        Just doc ->
            ( model, sendToFrontend clientId (ReceivedDocument documentHandling doc) )


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
    makeTagDict (getUserDocumentsForAuthor authorName model)


publicTags : Model -> Dict.Dict String (List { id : String, title : String })
publicTags model =
    let
        publicDocs =
            model.documentDict
                |> Dict.toList
                |> List.map (\( _, doc ) -> doc)
                |> List.filter (\doc -> doc.public)
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


hardDeleteDocument : ClientId -> Document.Document -> Model -> ( Model, Cmd msg )
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


gotAtmosphericRandomNumber : Model -> Result error String -> ( Model, Cmd msg )
gotAtmosphericRandomNumber model result =
    case result of
        Ok str ->
            case String.toInt (String.trim str) of
                Nothing ->
                    ( model, broadcast (MessageReceived { txt = "Could not get atomospheric integer", status = MSWhite }) )

                Just rn ->
                    let
                        newRandomSeed =
                            Random.initialSeed rn
                    in
                    ( { model
                        | randomAtmosphericInt = Just rn
                        , randomSeed = newRandomSeed
                      }
                    , broadcast (MessageReceived { txt = "Got atmospheric integer " ++ String.fromInt rn, status = MSWhite })
                    )

        Err _ ->
            ( model, Cmd.none )



-- USER


newConnectionDict username sessionId clientId connectionDict =
    case Dict.get username connectionDict of
        Nothing ->
            Dict.insert username [ { session = sessionId, client = clientId } ] connectionDict

        Just [] ->
            Dict.insert username [ { session = sessionId, client = clientId } ] connectionDict

        Just connections ->
            Dict.insert username ({ session = sessionId, client = clientId } :: connections) connectionDict


signUpUser : Model -> SessionId -> ClientId -> String -> Language -> String -> String -> String -> ( BackendModel, Cmd BackendMsg )
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
            }
    in
    case Authentication.insert user randomHex transitPassword model.authenticationDict of
        Err str ->
            ( { model | randomSeed = tokenData.seed }, sendToFrontend clientId (MessageReceived { txt = "Error: " ++ str, status = MSRed }) )

        Ok authDict ->
            ( { model | connectionDict = newConnectionDict_, randomSeed = tokenData.seed, authenticationDict = authDict, usersDocumentsDict = Dict.insert user.id [] model.usersDocumentsDict }
            , Cmd.batch
                [ sendToFrontend clientId (UserSignedUp user)
                , sendToFrontend clientId (MessageReceived { txt = "Success! Your account is set up.", status = MSGreen })
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
    "(" ++ truncateMiddle 2 0 session ++ ", " ++ truncateMiddle 2 2 client ++ ")"


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
