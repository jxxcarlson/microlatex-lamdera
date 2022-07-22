module Backend.Authentication exposing (signIn, signOut, signUpUser)

import Authentication
import Backend.Connection
import Backend.Document
import BoundedDeque
import Config
import Dict
import Docs
import Document
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import Hex
import Maybe.Extra
import Parser.Language
import Random
import Set
import Share
import Token
import Types exposing (BackendModel, BackendMsg, DocumentHandling(..), MessageStatus(..), ToFrontend(..))


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
                        List.filter (\d -> d.id /= Config.newsDocId) (Backend.Document.getMostRecentUserDocuments Types.SortByMostRecent Config.maxDocSearchLimit userData.user model.usersDocumentsDict model.documentDict)
                in
                ( { model | connectionDict = newConnectionDict_ }
                , Command.batch
                    [ -- TODO: restore the belo
                      Effect.Lamdera.sendToFrontend clientId (ReceivedDocuments StandardHandling <| (newsDoc :: docs))

                    --, sendToFrontend clientId (ReceivedPublicDocuments (searchForPublicDocuments Types.SortAlphabetically Config.maxDocSearchLimit (Just userData.user.username) "system:startup" model))
                    , Effect.Lamdera.sendToFrontend clientId (UserSignedUp userData.user clientId)
                    , Effect.Lamdera.sendToFrontend clientId (MessageReceived <| { txt = "Signed in as " ++ userData.user.username, status = MSGreen })
                    , Effect.Lamdera.sendToFrontend clientId (GotChatGroup chatGroup)
                    , Effect.Lamdera.broadcast (GotUsersWithOnlineStatus (Backend.Connection.getUsersAndOnlineStatus_ model.authenticationDict newConnectionDict_))
                    ]
                )

            else
                ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived <| { txt = "Sorry, password and username don't match", status = MSRed }) )

        Nothing ->
            ( model, Effect.Lamdera.sendToFrontend clientId (MessageReceived <| { txt = "Sorry, password and username don't match", status = MSRed }) )


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
            Backend.Document.fetchDocumentByIdCmd model clientId Config.signOutDocumentId StandardHandling

        notifications =
            Effect.Lamdera.broadcast (GotUsersWithOnlineStatus (Backend.Connection.getUsersAndOnlineStatus_ model.authenticationDict connectionDict)) :: List.map (\doc -> Share.narrowCast clientId doc connectionDict) documents

        updatedModel =
            Backend.Document.setDocumentsToReadOnlyWithUserName username model
    in
    ( { updatedModel
        | sharedDocumentDict = Share.removeUserFromSharedDocumentDict username model.sharedDocumentDict
        , connectionDict = connectionDict
      }
    , Command.batch <| pushSignOutDocCmd :: notifications
    )


newConnectionDict username sessionId clientId connectionDict =
    case Dict.get username connectionDict of
        Nothing ->
            Dict.insert username [ { session = sessionId, client = clientId } ] connectionDict

        Just [] ->
            Dict.insert username [ { session = sessionId, client = clientId } ] connectionDict

        Just connections ->
            Dict.insert username ({ session = sessionId, client = clientId } :: connections) connectionDict


signUpUser : BackendModel -> SessionId -> ClientId -> String -> Parser.Language.Language -> String -> String -> String -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
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
                |> Backend.Document.createDocumentAtBackend (Just user) deletedDocsFolder_
            , Command.batch
                [ Effect.Lamdera.sendToFrontend clientId (UserSignedUp user clientId)
                , Effect.Lamdera.sendToFrontend clientId (MessageReceived { txt = "Success! Your account is set up.", status = MSGreen })
                ]
            )
