module Backend.Update exposing
    ( applySpecial
    , createDocument
    , deleteDocument
    , fetchDocumentById
    , getDocumentByAuthorId
    , getDocumentById
    , getDocumentByPublicId
    , getHomePage
    , getUserDocuments
    , gotAtmosphericRandomNumber
    , saveDocument
    , searchForDocuments
    , searchForDocuments_
    , searchForPublicDocuments
    , signIn
    , signUpUser
    , updateAbstracts
    )

import Abstract
import Authentication
import Cmd.Extra
import Config
import DateTimeUtility
import Dict
import Document
import Hex
import Lamdera exposing (ClientId, broadcast, sendToFrontend)
import Maybe.Extra
import Parser.Language exposing (Language(..))
import Random
import Token
import Types exposing (AbstractDict, BackendModel, BackendMsg, DocPermissions(..), DocumentDict, ToFrontend(..), UsersDocumentsDict)
import User exposing (User)


type alias Model =
    BackendModel


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

                        XMarkdownLang ->
                            "# <<untitled>>\n\n"

                documentDict =
                    Dict.insert doc.id { doc | title = "<<untitled>>", content = content, modified = model.currentTime } mod.documentDict
            in
            { mod | documentDict = documentDict }

        newModel =
            List.foldl (\doc m -> updateDoc doc m) model (badDocs |> List.map Tuple.second)
    in
    ( newModel, sendToFrontend clientId (SendMessage ("Bad docs: " ++ String.fromInt (List.length badDocs))) )


getBadDocuments model =
    model.documentDict |> Dict.toList |> List.filter (\( _, doc ) -> doc.title == "")


getDocumentById model clientId id =
    case Dict.get id model.documentDict of
        Nothing ->
            ( model, sendToFrontend clientId (SendMessage "No document for that docId") )

        Just doc ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId (SendDocument CanEdit doc)
                , sendToFrontend clientId (SetShowEditor False)
                , sendToFrontend clientId (SendMessage ("id = " ++ doc.id))
                ]
            )


getDocumentByAuthorId model clientId authorId =
    case Dict.get authorId model.authorIdDict of
        Nothing ->
            ( model
            , sendToFrontend clientId (SendMessage "GetDocumentByAuthorId, No docId for that authorId")
            )

        Just docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model
                    , sendToFrontend clientId (SendMessage "No document for that docId")
                    )

                Just doc ->
                    ( model
                    , Cmd.batch
                        [ sendToFrontend clientId (SendDocument CanEdit doc)
                        , sendToFrontend clientId (SetShowEditor True)
                        , sendToFrontend clientId (SendMessage ("id = " ++ doc.id))
                        ]
                    )


getHomePage model clientId username =
    let
        docs =
            searchForDocuments_ ("home:" ++ username) model
    in
    case List.head docs of
        Nothing ->
            ( model, sendToFrontend clientId (SendMessage "home page not found") )

        Just doc ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId (SendMessage "Public document received")
                , sendToFrontend clientId (SendDocument CanEdit doc)
                , sendToFrontend clientId (SetShowEditor False)
                ]
            )


getDocumentByPublicId model clientId publicId =
    case Dict.get publicId model.publicIdDict of
        Nothing ->
            ( model, sendToFrontend clientId (SendMessage "GetDocumentByPublicId, No docId for that publicId") )

        Just docId ->
            case Dict.get docId model.documentDict of
                Nothing ->
                    ( model, sendToFrontend clientId (SendMessage "No document for that docId") )

                Just doc ->
                    ( model
                    , Cmd.batch
                        [ sendToFrontend clientId (SendMessage "Public document received")
                        , sendToFrontend clientId (SendDocument CanEdit doc)
                        , sendToFrontend clientId (SetShowEditor True)
                        , sendToFrontend clientId (SendMessage ("id = " ++ doc.id))
                        ]
                    )


fetchDocumentById model clientId docId maybeUserName =
    case Dict.get docId model.documentDict of
        Nothing ->
            ( model, sendToFrontend clientId (SendMessage "Couldn't find that document") )

        Just document ->
            if document.public || document.author == maybeUserName then
                ( model
                , Cmd.batch
                    [ -- sendToFrontend clientId (SendDocument ReadOnly document)
                      sendToFrontend clientId (SendDocument CanEdit document)

                    --, sendToFrontend clientId (SetShowEditor True)
                    , sendToFrontend clientId (SendMessage "Public document received")
                    ]
                )

            else
                ( model
                , Cmd.batch
                    [ sendToFrontend clientId (SendMessage "Sorry, that document is not accessible")
                    ]
                )


saveDocument model currentUser document =
    case currentUser of
        Nothing ->
            ( model, Cmd.none )

        Just _ ->
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
                    user.username ++ "-" ++ DateTimeUtility.toUtcSlug (String.left 1 publicIdTokenData.token) (String.slice 1 2 publicIdTokenData.token) model.currentTime

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
            [ sendToFrontend clientId (SendDocument CanEdit doc)
            , sendToFrontend clientId (SendMessage message)
            ]


signIn model clientId username encryptedPassword =
    case Dict.get username model.authenticationDict of
        Just userData ->
            if Authentication.verify username encryptedPassword model.authenticationDict then
                ( model
                , Cmd.batch
                    [ sendToFrontend clientId (SendDocuments <| getUserDocuments userData.user model.usersDocumentsDict model.documentDict)
                    , sendToFrontend clientId (UserSignedUp userData.user)
                    , sendToFrontend clientId (SendMessage <| "Success! your are signed in and your documents are now available")
                    ]
                )

            else
                ( model, sendToFrontend clientId (SendMessage <| "Sorry, password and username don't match") )

        Nothing ->
            ( model, sendToFrontend clientId (SendMessage <| "Sorry, password and username don't match") )


searchForDocuments model clientId maybeUsername key =
    ( model
    , Cmd.batch
        [ sendToFrontend clientId (SendDocuments (searchForUserDocuments maybeUsername key model))
        , sendToFrontend clientId (GotPublicDocuments (searchForPublicDocuments key model))
        ]
    )


searchForPublicDocuments : String -> Model -> List Document.Document
searchForPublicDocuments key model =
    searchForDocuments_ key model |> List.filter (\doc -> doc.public)


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



-- SYSTEM


deleteDocument : Document.Document -> Model -> ( Model, Cmd msg )
deleteDocument doc model =
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
    , Cmd.none
    )


gotAtmosphericRandomNumber : Model -> Result error String -> ( Model, Cmd msg )
gotAtmosphericRandomNumber model result =
    case result of
        Ok str ->
            case String.toInt (String.trim str) of
                Nothing ->
                    ( model, broadcast (SendMessage "Could not get atomospheric integer") )

                Just rn ->
                    let
                        newRandomSeed =
                            Random.initialSeed rn
                    in
                    ( { model
                        | randomAtmosphericInt = Just rn
                        , randomSeed = newRandomSeed
                      }
                    , broadcast (SendMessage ("Got atmospheric integer " ++ String.fromInt rn))
                    )

        Err _ ->
            ( model, Cmd.none )



-- USER


signUpUser : Model -> ClientId -> String -> String -> String -> String -> ( BackendModel, Cmd BackendMsg )
signUpUser model clientId username transitPassword realname email =
    let
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
            }
    in
    case Authentication.insert user randomHex transitPassword model.authenticationDict of
        Err str ->
            ( { model | randomSeed = tokenData.seed }, sendToFrontend clientId (SendMessage ("Error: " ++ str)) )

        Ok authDict ->
            ( { model | randomSeed = tokenData.seed, authenticationDict = authDict, usersDocumentsDict = Dict.insert user.id [] model.usersDocumentsDict }
            , Cmd.batch
                [ sendToFrontend clientId (UserSignedUp user)
                , sendToFrontend clientId (SendMessage "Success! You have set up your account")
                ]
            )


getUserDocuments : User -> UsersDocumentsDict -> DocumentDict -> List Document.Document
getUserDocuments user usersDocumentsDict documentDict =
    case Dict.get user.id usersDocumentsDict of
        Nothing ->
            []

        Just docIds ->
            List.foldl (\id acc -> Dict.get id documentDict :: acc) [] docIds |> Maybe.Extra.values


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
