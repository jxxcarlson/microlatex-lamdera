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
import Cmd.Extra
import Config
import Dict exposing (Dict)
import Docs
import Document
import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Message
import Random
import Share
import Time
import Types exposing (AbstractDict, BackendModel, BackendMsg(..), DocumentDict, DocumentLink, ToBackend(..), ToFrontend(..))
import User exposing (User)


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
        , Time.every (30 * 1000) Tick
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
      , documents =
            [ Docs.docsNotFound
            , Docs.notSignedIn
            ]
      }
    , Backend.Cmd.getRandomNumber
    )



-- SendDocument Types.SystemCanEdit newDoc


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
                [ sendToFrontend clientId (SendDocument Types.SystemCanEdit doc)
                , sendToFrontend clientId
                    (SendMessage
                        { content = doc.title ++ ", currentEditor = " ++ (doc.currentEditor |> Maybe.withDefault "Nothing")
                        , status = Types.MSWarning
                        }
                    )
                ]
            )

        Tick newTime ->
            -- Do regular tasks
            { model | currentTime = newTime } |> updateAbstracts |> Cmd.Extra.withNoCmd


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        -- CHAT
        ClearChatHistory groupName ->
            let
                newChatDict =
                    Dict.insert groupName [] model.chatDict
            in
            ( { model | chatDict = newChatDict }, Cmd.none )
                |> (\( m, c ) -> ( m, Chat.sendChatHistoryCmd groupName m clientId ))

        SendChatHistory groupName ->
            case Dict.get groupName model.chatGroupDict of
                Nothing ->
                    ( model, sendToFrontend clientId (SendMessage { content = groupName ++ ": no such group", status = Types.MSWarning }) )

                Just _ ->
                    ( model, Chat.sendChatHistoryCmd groupName model clientId )

        InsertChatGroup group ->
            ( { model | chatGroupDict = Dict.insert group.name group model.chatGroupDict }, Cmd.none )

        GetChatGroup groupName ->
            ( model, sendToFrontend clientId (GotChatGroup (Dict.get groupName model.chatGroupDict)) )

        ChatMsgSubmitted message ->
            ( { model | chatDict = Chat.insert message model.chatDict }, Cmd.batch (Chat.narrowCast model message) )

        DeliverUserMessage usermessage ->
            case Dict.get usermessage.to model.connectionDict of
                Nothing ->
                    ( model, sendToFrontend clientId (UndeliverableMessage usermessage) )

                Just connectionData ->
                    let
                        clientIds =
                            List.map .client connectionData

                        commands =
                            List.map (\clientId_ -> sendToFrontend clientId_ (UserMessageReceived usermessage)) clientIds
                    in
                    ( model, Cmd.batch commands )

        -- SHARE
        UpdateSharedDocumentDict doc ->
            ( Share.updateSharedDocumentDict doc model, Cmd.none )

        Narrowcast sendersName document ->
            ( model, Share.narrowCast sendersName document model.connectionDict )

        ClearConnectionDictBE ->
            ( { model | connectionDict = Dict.empty }, Cmd.none )

        RequestRefresh docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model, Cmd.none )

                Just doc ->
                    let
                        message =
                            { content = "Refreshing " ++ doc.title ++ " with currentEditor = " ++ (doc.currentEditor |> Maybe.withDefault "Nothing"), status = Types.MSGreen }
                    in
                    ( model
                    , Cmd.batch
                        [ sendToFrontend clientId (SendDocument Types.SystemCanEdit doc)
                        , sendToFrontend clientId (SendMessage message)
                        ]
                    )

        SignOutBE mUsername ->
            case mUsername of
                Nothing ->
                    ( model, Cmd.none )

                Just username ->
                    Backend.Update.removeSessionClient model sessionId clientId

        GetSharedDocuments username ->
            Backend.Update.getSharedDocuments model clientId username

        GetUserList ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId (GotUserList (Backend.Update.getUserData model))
                , sendToFrontend clientId (GotConnectionList (Backend.Update.getConnectionData model))
                , sendToFrontend clientId
                    (GotShareDocumentList
                        (model.sharedDocumentDict
                            |> Dict.toList
                            |> List.map (\( _, data ) -> ( data.author |> Maybe.withDefault "(anon)", data ))
                        )
                    )
                ]
            )

        RunTask ->
            ( model, Cmd.none )

        SearchForDocuments maybeUsername key ->
            Backend.Update.searchForDocuments model clientId maybeUsername key

        GetStatus ->
            ( model, sendToFrontend clientId (StatusReport (statusReport model)) )

        -- USER
        UpdateUserWith user ->
            ( { model | authenticationDict = Authentication.updateUser user model.authenticationDict }, Cmd.none )

        SignInBE username encryptedPassword ->
            Backend.Update.signIn model sessionId clientId username encryptedPassword

        SignUpBE username lang encryptedPassword realname email ->
            Backend.Update.signUpUser model sessionId clientId username lang encryptedPassword realname email

        -- DOCUMENTS
        GetUserTagsFromBE author ->
            ( model, sendToFrontend clientId (AcceptUserTags (Abstract.authorTagDict author model.abstractDict)) )

        GetPublicTagsFromBE ->
            ( model, sendToFrontend clientId (AcceptPublicTags (Abstract.publicTagDict model.documentDict model.abstractDict)) )

        CreateDocument maybeCurrentUser doc_ ->
            Backend.Update.createDocument model clientId maybeCurrentUser doc_

        SaveDocument document ->
            Backend.Update.saveDocument model document

        FetchDocumentById docId maybeCurrentUserId ->
            Backend.Update.fetchDocumentById model clientId docId maybeCurrentUserId

        GetDocumentByPublicId publicId ->
            Backend.Update.getDocumentByPublicId model clientId publicId

        GetHomePage username ->
            Backend.Update.getHomePage model clientId username

        GetDocumentByAuthorId authorId ->
            Backend.Update.getDocumentByAuthorId model clientId authorId

        GetDocumentById id ->
            Backend.Update.getDocumentById model clientId id

        GetPublicDocuments mUsername ->
            ( model, sendToFrontend clientId (GotPublicDocuments (Backend.Update.searchForPublicDocuments mUsername "startup" model)) )

        ApplySpecial _ _ ->
            -- stealId user id model |> Cmd.Extra.withNoCmd
            -- Backend.Update.applySpecial model clientId
            ( { model | sharedDocumentDict = Share.createShareDocumentDict model.documentDict }, Cmd.none )

        DeleteDocumentBE doc ->
            Backend.Update.deleteDocument clientId doc model


makeLink : String -> DocumentDict -> AbstractDict -> Maybe DocumentLink
makeLink docId documentDict abstractDict =
    case ( Dict.get docId documentDict, Dict.get docId abstractDict ) of
        ( Nothing, _ ) ->
            Nothing

        ( _, Nothing ) ->
            Nothing

        ( Just doc, Just abstr ) ->
            if doc.public then
                Just { digest = abstr.digest, label = abstr.title, url = Config.appUrl ++ "/p/" ++ doc.publicId }

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
    Config.appUrl ++ "/a/" ++ authorId


authorLink : String -> String
authorLink authorId =
    "[Author](" ++ authorUrl authorId ++ ")"


publicUrl : String -> String
publicUrl publicId =
    Config.appUrl ++ "/p/" ++ publicId


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
            Abstract.get doc.author doc.language doc.content


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
