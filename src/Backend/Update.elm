module Backend.Update exposing
    ( applySpecial
    , authorTags
    , createDocument
    , deliverUserMessage
    , getUserAndDocumentData
    , getUserData
    , getUserDocuments
    , gotAtmosphericRandomNumber
    , hardDeleteDocument
    , hardDeleteDocumentsWithIdList
    , insertDocument
    , join
    , publicTags
    , saveDocument
    , unlockDocuments
    , updateAbstracts
    , updateDocumentTags
    )

import Abstract
import Authentication
import Backend.Get
import Backend.Search
import Config
import Dict
import Document exposing (Document)
import DocumentTools
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId)
import Maybe.Extra
import Predicate
import Random
import Share
import Token
import Types exposing (AbstractDict, BackendModel, BackendMsg, DocumentDict, DocumentHandling(..), MessageStatus(..), ToFrontend(..), UsersDocumentsDict)
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



--cleanup model sessionId clientId =
--    ( { model
--        | connectionDict = Dict.empty
--        , editEvents = Deque.empty
--        , sharedDocumentDict = Share.removeConnectionFromSharedDocumentDict clientId model.sharedDocumentDict
--      }
--    , Cmd.none
--    )
-- TAGS


authorTags : String -> Model -> Dict.Dict String (List { id : String, title : String })
authorTags authorName model =
    makeTagDict (Backend.Search.getUserDocumentsForAuthor authorName model |> List.filter (\{ title } -> not (String.contains "(BAK)" title)))


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
    , Backend.Get.byIdCmd model clientId Config.documentDeletedNotice
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
