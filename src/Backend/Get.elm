module Backend.Get exposing
    ( fetchDocumentById
    , getDocumentByAuthorId
    , getDocumentByCmdId
    , getDocumentById
    , getDocumentByPublicId
    , getHomePage
    , getSharedDocuments
    )

import Backend.Document
import Backend.Search
import Dict
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId)
import IncludeFiles
import Maybe.Extra
import Share
import Types exposing (BackendModel, BackendMsg, DocumentHandling(..), MessageStatus(..), ToFrontend(..))
import Util


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
            Backend.Search.byKey_ (username ++ ":home") model
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
                , Backend.Document.fetchDocumentByIdCmd model clientId docId documentHandling
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
            Backend.Search.findDocumentByAuthorAndKey_ model author (author ++ ":" ++ key)
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
