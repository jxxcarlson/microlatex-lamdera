module Backend.Update exposing
    ( applySpecial
    , authorTags
    , createDocument
    , deleteDocument
    , fetchDocumentById
    , getConnectionData
    , getDocumentByAuthorId
    , getDocumentById
    , getDocumentByPublicId
    , getHomePage
    , getSharedDocuments
    , getUserData
    , getUserDocuments
    , gotAtmosphericRandomNumber
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
import Document
import DocumentTools
import Hex
import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Maybe.Extra
import Message
import Parser.Language exposing (Language(..))
import Random
import Share
import Token
import Types exposing (AbstractDict, BackendModel, BackendMsg, ConnectionData, ConnectionDict, DocumentDict, MessageStatus(..), SystemDocPermissions(..), ToFrontend(..), UsersDocumentsDict)
import User exposing (User)
import View.Utility


type alias Model =
    BackendModel


getSharedDocuments model clientId username =
    let
        docList =
            model.sharedDocumentDict
                |> Dict.toList
                |> List.map (\( _, data ) -> ( data.author |> Maybe.withDefault "(anon)", data ))

        docs1 =
            docList
                |> List.filter (\( _, data ) -> Share.isSharedToMe username data.share)

        docs2 =
            docList |> List.filter (\( _, data ) -> data.author == Just username)
    in
    ( model
    , sendToFrontend clientId (GotShareDocumentList (docs1 ++ docs2 |> List.sortBy (\( _, doc ) -> doc.title)))
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


applySpecial model clientId =
    let
        badDocs =
            getBadDocuments model

        updateDoc doc mod =
            let
                content =
                    case doc.language of
                        L0Lang ->
                            "| title\n<<untitled>>\n\n"

                        MicroLaTeXLang ->
                            "\\title{<<untitled>>}\n\n"

                        PlainTextLang ->
                            "| title\n<<untitled>>\n\n"

                        XMarkdownLang ->
                            "| title\n <<untitled>>\n\n"

                documentDict =
                    Dict.insert doc.id { doc | title = "<<untitled>>", content = content, modified = model.currentTime } mod.documentDict
            in
            { mod | documentDict = documentDict }

        newModel =
            List.foldl (\doc m -> updateDoc doc m) model (badDocs |> List.map Tuple.second)
    in
    ( newModel
    , sendToFrontend clientId
        (SendMessage
            { content = "Bad docs: " ++ String.fromInt (List.length badDocs), status = MSError }
        )
    )


getBadDocuments model =
    model.documentDict |> Dict.toList |> List.filter (\( _, doc ) -> doc.title == "")


getDocumentById model clientId id =
    case Dict.get id model.documentDict of
        Nothing ->
            ( model, sendToFrontend clientId (SendMessage { content = "No document for that docId", status = MSError }) )

        Just doc ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId (SendDocument SystemCanEdit doc)

                --, sendToFrontend clientId (SetShowEditor False)
                , sendToFrontend clientId (SendMessage { content = "Sending doc " ++ id, status = MSGreen })
                ]
            )


getDocumentByCmdId model clientId id =
    case Dict.get id model.documentDict of
        Nothing ->
            Cmd.none

        Just doc ->
            Cmd.batch
                [ sendToFrontend clientId (SendDocument SystemCanEdit doc)
                , sendToFrontend clientId (SetShowEditor False)
                ]


getDocumentByAuthorId model clientId authorId =
    case Dict.get authorId model.authorIdDict of
        Nothing ->
            ( model
            , sendToFrontend clientId (SendMessage { content = "GetDocumentByAuthorId, No docId for that authorId", status = MSWarning })
            )

        Just docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model
                    , sendToFrontend clientId (SendMessage { content = "No document for that docId", status = MSNormal })
                    )

                Just doc ->
                    ( model
                    , Cmd.batch
                        [ sendToFrontend clientId (SendDocument SystemCanEdit doc)
                        , sendToFrontend clientId (SetShowEditor True)
                        ]
                    )


getHomePage model clientId username =
    let
        docs =
            searchForDocuments_ ("home" ++ username) model
    in
    case List.head docs of
        Nothing ->
            ( model, sendToFrontend clientId (SendMessage { content = "home page not found", status = MSNormal }) )

        Just doc ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId (SendDocument SystemCanEdit doc)
                , sendToFrontend clientId (SetShowEditor False)
                ]
            )


getDocumentByPublicId model clientId publicId =
    case Dict.get publicId model.publicIdDict of
        Nothing ->
            ( model, sendToFrontend clientId (SendMessage { content = "GetDocumentByPublicId, No docId for that publicId", status = MSNormal }) )

        Just docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model, sendToFrontend clientId (SendMessage { content = "No document for that docId", status = MSNormal }) )

                Just doc ->
                    ( model
                    , Cmd.batch
                        [ sendToFrontend clientId (SendDocument SystemCanEdit doc)
                        , sendToFrontend clientId (SetShowEditor True)
                        ]
                    )


fetchDocumentById model clientId docId maybeUserName =
    case Dict.get docId model.documentDict of
        Nothing ->
            ( model, sendToFrontend clientId (SendMessage { content = "Couldn't find that document", status = MSNormal }) )

        Just document ->
            if document.public || document.author == maybeUserName then
                ( model
                , Cmd.batch
                    [ -- sendToFrontend clientId (SendDocument ReadOnly document)
                      sendToFrontend clientId (SendDocument SystemCanEdit document)

                    --, sendToFrontend clientId (SetShowEditor True)
                    ]
                )

            else
                ( model
                , Cmd.batch
                    [ sendToFrontend clientId (SendMessage { content = "Sorry, that document is not accessible", status = MSNormal })
                    ]
                )


saveDocument model document =
    -- TODO: review this for safety
    let
        documentDict =
            Dict.insert document.id { document | modified = model.currentTime } model.documentDict
    in
    ( { model | documentDict = documentDict }, Cmd.none )


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

        message =
            --  "userIds : " ++ String.fromInt (List.length list)
            "Author link: " ++ Config.appUrl ++ "/a/au-" ++ authorIdTokenData.token ++ ", Public link:" ++ Config.appUrl ++ "/p/pu-" ++ humanFriendlyPublicId
    in
    { model
        | randomSeed = publicIdTokenData.seed
        , documentDict = documentDict
        , authorIdDict = authorIdDict
        , publicIdDict = publicIdDict
        , usersDocumentsDict = usersDocumentsDict
    }
        |> Cmd.Extra.withCmds
            [ sendToFrontend clientId (SendDocument SystemCanEdit doc)
            , sendToFrontend clientId (SendMessage { content = message, status = MSNormal })
            ]


removeSessionClient model sessionId clientId =
    ( { model | connectionDict = removeSessionFromDict sessionId clientId model.connectionDict }, Cmd.none )


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
                    [ sendToFrontend clientId (ReceivedDocuments <| getMostRecentUserDocuments Types.SortAlphabetically Config.maxDocSearchLimit userData.user model.usersDocumentsDict model.documentDict)
                    , sendToFrontend clientId (ReceivedPublicDocuments (searchForPublicDocuments Types.SortAlphabetically Config.maxDocSearchLimit (Just userData.user.username) "system:startup" model))
                    , sendToFrontend clientId (UserSignedUp userData.user)
                    , sendToFrontend clientId (SendMessage <| { content = "Signed in", status = MSNormal })
                    , sendToFrontend clientId (GotChatGroup chatGroup)
                    ]
                )

            else
                ( model, sendToFrontend clientId (SendMessage <| { content = "Sorry, password and username don't match", status = MSNormal }) )

        Nothing ->
            ( model, sendToFrontend clientId (SendMessage <| { content = "Sorry, password and username don't match", status = MSNormal }) )


searchForDocuments : Model -> ClientId -> Maybe String -> String -> ( Model, Cmd backendMsg )
searchForDocuments model clientId maybeUsername key =
    ( model
    , Cmd.batch
        [ sendToFrontend clientId (ReceivedDocuments (searchForUserDocuments maybeUsername key model))
        , sendToFrontend clientId (ReceivedPublicDocuments (searchForPublicDocuments Types.SortAlphabetically Config.maxDocSearchLimit maybeUsername key model))
        ]
    )


searchForDocumentsByAuthorAndKey model clientId key =
    ( model, sendToFrontend clientId (ReceivedDocuments (searchForDocumentsByAuthorAndKey_ model clientId key)) )


searchForDocumentsByAuthorAndKey_ model clientId key =
    case String.split "/" key of
        [] ->
            []

        author :: [] ->
            getUserDocumentsForAuthor author model

        author :: firstKey :: rest ->
            getUserDocumentsForAuthor author model |> List.filter (\doc -> List.member firstKey doc.tags)



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
    List.map (\tag -> { id = id, title = title, tag = tag }) tags


unroll : List { id : String, title : String, tags : List String } -> List { id : String, title : String, tag : String }
unroll list =
    List.map unroll_ list |> List.concat


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


searchForPublicDocuments : Types.SortMode -> Int -> Maybe String -> String -> Model -> List Document.Document
searchForPublicDocuments sortMode limit mUsername key model =
    searchForDocuments_ key model
        |> List.filter (\doc -> doc.public || View.Utility.isSharedToMe_ mUsername doc)
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


deleteDocument : ClientId -> Document.Document -> Model -> ( Model, Cmd msg )
deleteDocument clientId doc model =
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
                    ( model, broadcast (SendMessage { content = "Could not get atomospheric integer", status = MSNormal }) )

                Just rn ->
                    let
                        newRandomSeed =
                            Random.initialSeed rn
                    in
                    ( { model
                        | randomAtmosphericInt = Just rn
                        , randomSeed = newRandomSeed
                      }
                    , broadcast (SendMessage { content = "Got atmospheric integer " ++ String.fromInt rn, status = MSNormal })
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
            }
    in
    case Authentication.insert user randomHex transitPassword model.authenticationDict of
        Err str ->
            ( { model | randomSeed = tokenData.seed }, sendToFrontend clientId (SendMessage { content = "Error: " ++ str, status = MSError }) )

        Ok authDict ->
            ( { model | connectionDict = newConnectionDict_, randomSeed = tokenData.seed, authenticationDict = authDict, usersDocumentsDict = Dict.insert user.id [] model.usersDocumentsDict }
            , Cmd.batch
                [ sendToFrontend clientId (UserSignedUp user)
                , sendToFrontend clientId (SendMessage { content = "Success! You have set up your account", status = MSNormal })
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
