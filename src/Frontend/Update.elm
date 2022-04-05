module Frontend.Update exposing
    ( addDocToCurrentUser
    , adjustId
    , closeEditor
    , debounceMsg
    , deleteDocument
    , exportToLaTeX
    , exportToMarkdown
    , firstSyncLR
    , handleSignIn
    , handleSignOut
    , handleSignUp
    , handleUrlRequest
    , inputText
    , inputTitle
    , isMaster
    , newDocument
    , nextSyncLR
    , openEditor
    , render
    , runSpecial
    , searchText
    , setDocumentAsCurrent
    , setDocumentInPhoneAsCurrent
    , setInitialEditorContent
    , setLanguage
    , setPublic
    , setPublicDocumentAsCurrentById
    , setUserLanguage
    , setViewportForElement
    , syncLR
    , updateCurrentDocument
    , updateKeys
    , updateWithViewport
    )

--

import Authentication
import BoundedDeque exposing (BoundedDeque)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Cmd.Extra exposing (withCmd, withNoCmd)
import Compiler.ASTTools
import Compiler.Acc
import Compiler.DifferentialParser
import Config
import Debounce
import Docs
import Document exposing (Document)
import File.Download as Download
import Frontend.Cmd
import Keyboard
import Lamdera exposing (sendToBackend)
import List.Extra
import Markup
import Message
import Parser.Language exposing (Language(..))
import Process
import Render.LaTeX as LaTeX
import Render.Markup
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings as Settings
import Task
import Types exposing (DocumentDeleteState(..), DocumentList(..), FrontendModel, FrontendMsg(..), MessageStatus(..), PhoneMode(..), PopupState(..), SystemDocPermissions(..), ToBackend(..))
import User exposing (User)
import View.Utility


exportToLaTeX model =
    let
        textToExport =
            LaTeX.export Settings.defaultSettings model.editRecord.parsed

        fileName =
            (model.currentDocument |> Maybe.map .title |> Maybe.withDefault "doc") ++ ".tex"
    in
    ( model, Download.string fileName "application/x-latex" textToExport )


exportToMarkdown model =
    let
        markdownText =
            -- TODO:implement this
            -- L1.Render.Markdown.transformDocument model.currentDocument.content
            "Not implemented"

        fileName_ =
            "foo" |> String.replace " " "-" |> String.toLower |> (\name -> name ++ ".md")
    in
    ( model, Download.string fileName_ "text/markdown" markdownText )


setPublic model doc public =
    let
        newDocument_ =
            { doc | public = public }

        documents =
            List.Extra.setIf (\d -> d.id == newDocument_.id) newDocument_ model.documents
    in
    ( { model | documents = documents, currentDocument = Just newDocument_, inputTitle = "" }, sendToBackend (SaveDocument newDocument_) )


setPublicDocumentAsCurrentById : FrontendModel -> String -> ( FrontendModel, Cmd FrontendMsg )
setPublicDocumentAsCurrentById model id =
    case List.filter (\doc -> doc.id == id) model.publicDocuments |> List.head of
        Nothing ->
            ( { model | messages = [ { content = "No document of id [" ++ id ++ "] found", status = MSNormal } ] }, Cmd.none )

        Just doc ->
            let
                newEditRecord =
                    Compiler.DifferentialParser.init doc.language doc.content
            in
            ( { model
                | currentDocument = Just doc
                , sourceText = doc.content
                , initialText = doc.content
                , editRecord = newEditRecord
                , title = Compiler.ASTTools.title newEditRecord.parsed
                , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
                , messages = [ { content = "id = " ++ doc.id, status = MSNormal } ]
                , counter = model.counter + 1
              }
            , Cmd.batch [ View.Utility.setViewPortToTop ]
            )


deleteDocument model =
    case model.currentDocument of
        Nothing ->
            ( model, Cmd.none )

        Just doc ->
            let
                newUser =
                    case model.currentUser of
                        Nothing ->
                            Nothing

                        Just _ ->
                            deleteDocFromCurrentUser model doc
            in
            ( { model
                | currentDocument = Just Docs.deleted
                , documents = List.filter (\d -> d.id /= doc.id) model.documents
                , deleteDocumentState = WaitingForDeleteAction
                , currentUser = newUser
              }
            , Cmd.batch [ sendToBackend (DeleteDocumentBE doc), Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById Config.documentDeletedNotice)) ]
            )


setInitialEditorContent model =
    case model.currentDocument of
        Nothing ->
            ( { model | messages = [ { content = "Could not set editor content: there is no current document", status = MSNormal } ] }, Cmd.none )

        Just doc ->
            ( { model | initialText = doc.content }, Cmd.none )


searchText model =
    let
        ids =
            Compiler.ASTTools.matchingIdsInAST model.searchSourceText model.editRecord.parsed

        ( cmd, id ) =
            case List.head ids of
                Nothing ->
                    ( Cmd.none, "(none)" )

                Just id_ ->
                    ( View.Utility.setViewportForElement id_, id_ )
    in
    ( { model | selectedId = id, searchCount = model.searchCount + 1, messages = [ { content = "ids: " ++ String.join ", " ids, status = MSNormal } ] }, cmd )


save : String -> Cmd FrontendMsg
save s =
    Task.perform Saved (Task.succeed s)


inputTitle model str =
    ( { model | inputTitle = str }, Cmd.none )


inputText model str =
    let
        -- Push your values here.
        ( debounce, cmd ) =
            Debounce.push debounceConfig str model.debounce
    in
    let
        editRecord =
            Compiler.DifferentialParser.update model.editRecord str

        messages : List String
        messages =
            Render.Markup.getMessages
                editRecord.parsed
    in
    ( { model
        | sourceText = str
        , editRecord = editRecord
        , title = Compiler.ASTTools.title editRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents editRecord.parsed
        , messages = [ { content = String.join ", " messages, status = MSNormal } ]
        , debounce = debounce
        , counter = model.counter + 1
      }
    , cmd
    )


debounceMsg model msg_ =
    let
        ( debounce, cmd ) =
            Debounce.update
                debounceConfig
                (Debounce.takeLast save)
                msg_
                model.debounce
    in
    ( { model | debounce = debounce }
    , cmd
    )


debounceConfig : Debounce.Config FrontendMsg
debounceConfig =
    { strategy = Debounce.soon 300
    , transform = DebounceMsg
    }


render model msg_ =
    case msg_ of
        Render.Msg.SendMeta _ ->
            -- ( { model | lineNumber = m.loc.begin.row, message = "line " ++ String.fromInt (m.loc.begin.row + 1) }, Cmd.none )
            ( model, Cmd.none )

        Render.Msg.SendId line ->
            -- TODO: the below (using id also for line number) is not a great idea.
            ( { model | messages = [ { content = "Line " ++ (line |> String.toInt |> Maybe.withDefault 0 |> (\x -> x + 1) |> String.fromInt), status = MSNormal } ], linenumber = String.toInt line |> Maybe.withDefault 0 }, Cmd.none )

        Render.Msg.SelectId id ->
            -- the element with this id will be highlighted
            ( { model | selectedId = id }, View.Utility.setViewportForElement id )

        GetPublicDocument id ->
            ( model, sendToBackend (FetchDocumentById id (Maybe.map .username model.currentUser)) )


setLanguage dismiss lang model =
    if dismiss then
        ( { model | language = lang, popupState = NoPopup }, Cmd.none )

    else
        ( { model | language = lang }, Cmd.none )


setUserLanguage lang model =
    ( { model | inputLanguage = lang, popupState = NoPopup }, Cmd.none )


firstSyncLR model searchSourceText =
    let
        data =
            let
                foundIds_ =
                    Compiler.ASTTools.matchingIdsInAST searchSourceText model.editRecord.parsed

                id_ =
                    List.head foundIds_ |> Maybe.withDefault "(nothing)"
            in
            { foundIds = foundIds_
            , foundIdIndex = 1
            , cmd = View.Utility.setViewportForElement id_
            , selectedId = id_
            , searchCount = 0
            }
    in
    ( { model
        | selectedId = data.selectedId
        , foundIds = data.foundIds
        , foundIdIndex = data.foundIdIndex
        , searchCount = data.searchCount
        , messages = [ { content = ("[" ++ adjustId data.selectedId ++ "]") :: List.map adjustId data.foundIds |> String.join ", ", status = MSNormal } ]
      }
    , data.cmd
    )


nextSyncLR model =
    let
        id_ =
            List.Extra.getAt model.foundIdIndex model.foundIds |> Maybe.withDefault "(nothing)"
    in
    ( { model
        | selectedId = id_
        , foundIdIndex = modBy (List.length model.foundIds) (model.foundIdIndex + 1)
        , searchCount = model.searchCount + 1
        , messages = [ { content = ("[" ++ adjustId id_ ++ "]") :: List.map adjustId model.foundIds |> String.join ", ", status = MSNormal } ]
      }
    , View.Utility.setViewportForElement id_
    )


syncLR model =
    let
        data =
            if model.foundIdIndex == 0 then
                let
                    foundIds_ =
                        Compiler.ASTTools.matchingIdsInAST model.searchSourceText model.editRecord.parsed

                    id_ =
                        List.head foundIds_ |> Maybe.withDefault "(nothing)"
                in
                { foundIds = foundIds_
                , foundIdIndex = 1
                , cmd = View.Utility.setViewportForElement id_
                , selectedId = id_
                , searchCount = 0
                }

            else
                let
                    id_ =
                        List.Extra.getAt model.foundIdIndex model.foundIds |> Maybe.withDefault "(nothing)"
                in
                { foundIds = model.foundIds
                , foundIdIndex = modBy (List.length model.foundIds) (model.foundIdIndex + 1)
                , cmd = View.Utility.setViewportForElement id_
                , selectedId = id_
                , searchCount = model.searchCount + 1
                }
    in
    ( { model
        | selectedId = data.selectedId
        , foundIds = data.foundIds
        , foundIdIndex = data.foundIdIndex
        , searchCount = data.searchCount
        , messages = [ { content = ("!![" ++ adjustId data.selectedId ++ "]") :: List.map adjustId data.foundIds |> String.join ", ", status = MSNormal } ]
      }
    , data.cmd
    )


adjustId : String -> String
adjustId str =
    case String.toInt str of
        Nothing ->
            str

        Just n ->
            String.fromInt (n + 2)


setViewportForElement model result =
    case result of
        Ok ( element, viewport ) ->
            ( { model | messages = [] }
              -- [ { content = model.message ++ ", setting viewport", status = MSNormal } ] }
            , View.Utility.setViewPortForSelectedLine element viewport
            )

        Err _ ->
            -- TODO: restore error message
            -- ( { model | message = model.message ++ ", could not set viewport" }, Cmd.none )
            ( model, Cmd.none )


isMaster editRecord =
    Compiler.ASTTools.existsBlockWithName editRecord.parsed "collection"


addDocToCurrentUser : FrontendModel -> Document -> Maybe User
addDocToCurrentUser model doc =
    case model.currentUser of
        Nothing ->
            Nothing

        Just user ->
            let
                isNotInDeque : Document -> BoundedDeque Document.DocumentInfo -> Bool
                isNotInDeque doc_ deque =
                    BoundedDeque.filter (\item -> item.id == doc_.id) deque |> BoundedDeque.isEmpty

                docs =
                    if isNotInDeque doc user.docs then
                        BoundedDeque.pushFront (Document.toDocInfo doc) user.docs

                    else
                        user.docs
                            |> BoundedDeque.filter (\item -> item.id /= doc.id)
                            |> BoundedDeque.pushFront (Document.toDocInfo doc)

                newUser =
                    { user | docs = docs }
            in
            Just newUser


deleteDocFromCurrentUser model doc =
    case model.currentUser of
        Nothing ->
            Nothing

        Just user ->
            let
                newDocs =
                    BoundedDeque.filter (\d -> d.id /= doc.id) user.docs

                newUser =
                    { user | docs = newDocs }
            in
            Just newUser



-- LOCKING AND UNLOCKING DOCUMENTS


requestLock : Document -> ( FrontendModel, List (Cmd FrontendMsg) ) -> ( FrontendModel, List (Cmd FrontendMsg) )
requestLock doc ( model, cmds ) =
    if shouldMakeRequest model.currentUser doc model.showEditor then
        let
            message =
                { content = "Sending requestLock for " ++ currentUserName model.currentUser ++ ", " ++ doc.id, status = MSGreen }
        in
        ( { model | messages = message :: model.messages }, sendToBackend (RequestLock (currentUserName model.currentUser) doc.id) :: cmds )

    else
        let
            message =
                { content = "Not sending requestLock", status = MSGreen }
        in
        ( { model | messages = message :: model.messages }, cmds )


requestRefresh : String -> ( FrontendModel, List (Cmd FrontendMsg) ) -> ( FrontendModel, List (Cmd FrontendMsg) )
requestRefresh docId ( model, cmds ) =
    let
        message =
            { content = "Requesting refresh for " ++ docId, status = MSGreen }
    in
    ( { model | messages = message :: model.messages }, sendToBackend (RequestRefresh docId) :: cmds )


currentUserName : Maybe User -> String
currentUserName mUser =
    mUser |> Maybe.map .username |> Maybe.withDefault "((nobody))"


currentDocumentId : Maybe Document -> String
currentDocumentId mDoc =
    mDoc |> Maybe.map .id |> Maybe.withDefault "((no docId))"


shouldMakeRequest : Maybe User -> Document -> Bool -> Bool
shouldMakeRequest mUser doc showEditor =
    (View.Utility.isSharedToMe mUser doc
        || View.Utility.iOwnThisDocument mUser doc
    )
        && showEditor


requestUnlock : ( FrontendModel, List (Cmd FrontendMsg) ) -> ( FrontendModel, List (Cmd FrontendMsg) )
requestUnlock ( model, cmds ) =
    case model.currentDocument of
        Nothing ->
            ( model, cmds )

        Just doc ->
            let
                mess =
                    { content = "Sending requestUnLock", status = MSGreen }
            in
            if shouldMakeRequest model.currentUser doc model.showEditor then
                -- if View.Utility.isSharedToMe model.currentUser doc || View.Utility.iOwnThisDocument model.currentUser doc then
                ( { model | messages = mess :: model.messages }, sendToBackend (RequestUnlock (currentUserName model.currentUser) (currentDocumentId model.currentDocument)) :: cmds )

            else
                let
                    message =
                        { content = "I am not making an unlock request", status = MSWarning }
                in
                ( { model | messages = [ message ] }, cmds )


batch =
    \( m, cmds ) -> ( m, Cmd.batch cmds )



-- SET DOCUMENT AS CURRENT


setDocumentAsCurrent : FrontendModel -> Document.Document -> SystemDocPermissions -> ( FrontendModel, Cmd FrontendMsg )
setDocumentAsCurrent model doc permissions =
    if model.showEditor then
        -- if we are not in the editor, unlock the previous current document if need be
        -- and loc the new document (doc)
        ( model, [] )
            |> setDocumentAsCurrentAux doc permissions
            -- |> requestUnlockPreviousThenLockCurrent doc permissions
            |> requestLock doc
            |> batch

    else
        ( model, [] )
            -- if we are not in the editor, refresh the document so as
            -- to be looking at the most recent copy
            |> setDocumentAsCurrentAux doc permissions
            |> requestRefresh doc.id
            |> batch


requestUnlockPreviousThenLockCurrent : Document.Document -> SystemDocPermissions -> ( FrontendModel, List (Cmd FrontendMsg) ) -> ( FrontendModel, List (Cmd FrontendMsg) )
requestUnlockPreviousThenLockCurrent doc permissions ( model, cmds ) =
    if Just doc /= model.currentDocument then
        ( model, cmds )
            --|> requestUnlock
            |> requestLock doc

    else
        ( model, cmds )
            |> requestLock doc


setDocumentAsCurrentAux : Document.Document -> SystemDocPermissions -> ( FrontendModel, List (Cmd FrontendMsg) ) -> ( FrontendModel, List (Cmd FrontendMsg) )
setDocumentAsCurrentAux doc permissions ( model, cmds ) =
    let
        newEditRecord =
            Compiler.DifferentialParser.init doc.language doc.content

        currentMasterDocument =
            if isMaster newEditRecord then
                Just doc

            else
                Nothing

        ( readers, editors ) =
            View.Utility.getReadersAndEditors (Just doc)

        newCurrentUser =
            addDocToCurrentUser model doc
    in
    ( { model
        | currentDocument = Just doc
        , currentMasterDocument = currentMasterDocument
        , sourceText = doc.content
        , initialText = doc.content
        , editRecord = newEditRecord
        , title =
            Compiler.ASTTools.title newEditRecord.parsed
        , tableOfContents = Compiler.ASTTools.tableOfContents newEditRecord.parsed
        , messages = []
        , permissions = setPermissions model.currentUser permissions doc
        , counter = model.counter + 1
        , language = doc.language
        , currentUser = newCurrentUser
        , inputReaders = readers
        , inputEditors = editors
      }
    , View.Utility.setViewPortToTop :: cmds
    )



-- OPEN AND CLOSE EDITOR


openEditor : Document -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
openEditor doc model =
    ( { model
        | showEditor = True
        , sourceText = doc.content
        , initialText = ""
      }
    , [ Frontend.Cmd.setInitialEditorContent 20 ]
    )
        -- |> requestLock doc
        --|> requestUnlockPreviousThenLockCurrent doc SystemCanEdit
        |> requestLock doc
        |> batch


closeEditor model =
    ( { model | initialText = "", popupState = NoPopup }
    , []
    )
        |> requestUnlock
        |> (\( m, cmds ) -> ( { m | showEditor = False }, cmds ))
        |> batch



-- END: LOCKING AND UNLOCKING DOCUMENTS


setPermissions currentUser permissions document =
    case document.author of
        Nothing ->
            permissions

        Just author ->
            if Just author == Maybe.map .username currentUser then
                SystemCanEdit

            else
                permissions


setDocumentInPhoneAsCurrent model doc permissions =
    let
        ast =
            Markup.parse doc.language doc.content |> Compiler.Acc.transformST doc.language
    in
    ( { model
        | currentDocument = Just doc
        , sourceText = doc.content
        , initialText = doc.content
        , title = Compiler.ASTTools.title ast
        , tableOfContents = Compiler.ASTTools.tableOfContents ast
        , messages = [ { content = "id = " ++ doc.id, status = MSNormal } ]
        , permissions = setPermissions model.currentUser permissions doc
        , counter = model.counter + 1
        , phoneMode = PMShowDocument
      }
    , View.Utility.setViewPortToTop
    )


runSpecial model =
    case model.currentUser of
        Nothing ->
            model |> withNoCmd

        Just user ->
            if user.username == "jxxcarlson" then
                model |> withCmd (sendToBackend (ApplySpecial user model.inputSpecial))

            else
                model |> withNoCmd


handleSignOut model =
    let
        cmd =
            case model.currentUser of
                Nothing ->
                    Cmd.none

                Just user ->
                    sendToBackend (UpdateUserWith user)
    in
    ( { model
        | currentUser = Nothing
        , currentDocument = Nothing
        , currentMasterDocument = Nothing
        , documents = []
        , messages = [ { content = "Signed out", status = MSNormal } ]
        , inputSearchKey = ""
        , inputUsername = ""
        , inputPassword = ""
        , documentList = StandardList
        , maximizedIndex = Types.MPublicDocs
        , popupState = NoPopup
        , showEditor = False
      }
    , Cmd.batch
        [ Nav.pushUrl model.key "/"
        , cmd
        , sendToBackend (UnlockDocuments (model.currentUser |> Maybe.map .id))
        , sendToBackend (GetDocumentById Config.welcomeDocId)
        , sendToBackend (GetPublicDocuments Nothing)
        ]
    )


handleSignIn model =
    if String.length model.inputPassword >= 8 then
        ( model
        , sendToBackend (SignInBE model.inputUsername (Authentication.encryptForTransit model.inputPassword))
        )

    else
        ( { model | messages = [ { content = "Password must be at least 8 letters long.", status = MSNormal } ] }, Cmd.none )


handleSignUp model =
    let
        errors =
            []
                |> reject (String.length model.inputUsername < 4) "username: at least three letters"
                |> reject (String.toLower model.inputUsername /= model.inputUsername) "username: all lower case characters"
                |> reject (model.inputPassword == "") "password: cannot be empty"
                |> reject (String.length model.inputPassword < 8) "password: at least 8 letters long."
                |> reject (model.inputPassword /= model.inputPasswordAgain) "passwords do not match"
                |> reject (model.inputEmail == "") "missing email address"
                |> reject (model.inputRealname == "") "missing real name"
    in
    if List.isEmpty errors then
        ( model
        , sendToBackend (SignUpBE model.inputUsername model.inputLanguage (Authentication.encryptForTransit model.inputPassword) model.inputRealname model.inputEmail)
        )

    else
        ( { model | messages = [ { content = String.join "; " errors, status = MSNormal } ] }, Cmd.none )


reject : Bool -> String -> List String -> List String
reject condition message messages =
    if condition then
        message :: messages

    else
        messages


handleUrlRequest model urlRequest =
    case urlRequest of
        Internal url ->
            let
                cmd =
                    case .fragment url of
                        Just internalId ->
                            -- internalId is the part after '#', if present
                            View.Utility.setViewportForElement internalId

                        Nothing ->
                            --if String.left 3 url.path == "/a/" then
                            sendToBackend (GetDocumentByAuthorId (String.dropLeft 3 url.path))

                --
                --else if String.left 3 url.path == "/p/" then
                --    sendToBackend (GetDocumentByPublicId (String.dropLeft 3 url.path))
                --
                --else
                --    Nav.pushUrl model.key (Url.toString url)
            in
            ( model, cmd )

        External url ->
            ( model
            , Nav.load url
            )


updateKeys model keyMsg =
    let
        pressedKeys =
            Keyboard.update keyMsg model.pressedKeys

        doSync =
            if List.member Keyboard.Control pressedKeys && List.member (Keyboard.Character "S") pressedKeys then
                not model.doSync

            else
                model.doSync
    in
    ( { model | pressedKeys = pressedKeys, doSync = doSync }
    , Cmd.none
    )


updateWithViewport vp model =
    let
        w =
            round vp.viewport.width

        h =
            round vp.viewport.height
    in
    ( { model
        | windowWidth = w
        , windowHeight = h
      }
    , Cmd.none
    )


newDocument model =
    let
        emptyDoc =
            Document.empty

        documentsCreatedCounter =
            model.documentsCreatedCounter + 1

        title =
            case model.language of
                MicroLaTeXLang ->
                    "\\title{" ++ model.inputTitle ++ "}\n\n"

                _ ->
                    "| title\n" ++ model.inputTitle ++ "\n\n"

        doc =
            { emptyDoc
                | title = title
                , content = title
                , author = Maybe.map .username model.currentUser
                , language = model.language
            }
    in
    ( { model | showEditor = True, documentsCreatedCounter = documentsCreatedCounter, popupState = NoPopup }
    , Cmd.batch [ sendToBackend (CreateDocument model.currentUser doc) ]
    )


updateCurrentDocument : Document -> FrontendModel -> FrontendModel
updateCurrentDocument doc model =
    { model | currentDocument = Just doc }
