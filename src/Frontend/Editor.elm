module Frontend.Editor exposing
    ( addUserToCurrentEditorsOfDocument
    , closeEditor
    , debounceMsg
    , inputCursor
    , inputText
    , open
    , openEditor
    , setInitialEditorContent
    , setToReadOnlyIfNoEditors
    )

import CollaborativeEditing.NetworkModel as NetworkModel
import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Debounce
import Document exposing (Document)
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Effect.Task
import Frontend.Cmd
import Predicate
import Render.Markup
import Types exposing (FrontendModel, FrontendMsg, MessageStatus(..), ToBackend)
import User exposing (User)
import Util


open model =
    case model.currentDocument of
        Nothing ->
            ( { model | messages = [ { txt = "No document to open in editor", status = Types.MSWhite } ] }, Effect.Command.none )

        Just doc ->
            openEditor doc model


{-| }
When the editor is opened, the current user is added to the document's
current editor list. This changed needs to saved to the backend and
narrowcast to the other users who to whom this document is shared,
so that **all** relevant frontends remain in sync. Otherwise there
will be shared set of editors among the various users editing the document.
-}
openEditor : Document -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
openEditor doc model =
    case model.currentUser of
        Nothing ->
            ( model, Effect.Command.none )

        Just currentUser ->
            let
                updatedDoc =
                    addUserToCurrentEditorsOfDocument model.currentUser doc

                sendersName =
                    currentUser.username

                sendersId =
                    currentUser.id
            in
            ( { model
                | showEditor = True
                , sourceText = doc.content
                , oTDocument = { docId = doc.id, cursor = 0, content = doc.content }
                , initialText = ""
                , currentDocument = Just updatedDoc
              }
            , Effect.Command.batch
                [ Frontend.Cmd.setInitialEditorContent 20
                , if Predicate.documentIsMineOrSharedToMe (Just updatedDoc) model.currentUser then
                    Effect.Lamdera.sendToBackend (Types.AddEditor currentUser updatedDoc)

                  else
                    Effect.Command.none
                , if Predicate.shouldNarrowcast model.currentUser (Just updatedDoc) then
                    Effect.Lamdera.sendToBackend (Types.NarrowcastExceptToSender sendersName sendersId updatedDoc)

                  else
                    Effect.Command.none
                ]
            )


setInitialEditorContent : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
setInitialEditorContent model =
    case model.currentDocument of
        Nothing ->
            ( { model | messages = [ { txt = "Could not set editor content: there is no current document", status = MSWhite } ] }, Effect.Command.none )

        Just doc ->
            ( { model | initialText = doc.content }, Effect.Command.none )


closeEditor : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
closeEditor model =
    let
        updatedDoc : Maybe Document
        updatedDoc =
            User.mRemoveEditor model.currentUser model.currentDocument
                |> Maybe.map setToReadOnlyIfNoEditors

        saveCmd =
            case updatedDoc of
                Nothing ->
                    Effect.Command.none

                Just doc ->
                    Effect.Command.batch
                        [ Effect.Lamdera.sendToBackend (Types.SaveDocument model.currentUser doc)
                        , if Predicate.documentIsMineOrSharedToMe updatedDoc model.currentUser then
                            Effect.Lamdera.sendToBackend (Types.NarrowcastExceptToSender (User.currentUsername model.currentUser) (User.currentUserId model.currentUser) doc)

                          else
                            Effect.Command.none
                        ]

        documents =
            case updatedDoc of
                Nothing ->
                    model.documents

                Just doc ->
                    Document.updateDocumentInList doc model.documents
    in
    ( { model
        | currentDocument = updatedDoc
        , documents = documents
        , initialText = ""
        , popupState = Types.NoPopup
        , showEditor = False
      }
    , saveCmd
    )


handleCursor : { a | position : Int, source : String } -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleCursor { position, source } model =
    case Maybe.map .id model.currentUser of
        Nothing ->
            ( model, Effect.Command.none )

        Just _ ->
            handleEditorChange model position source


{-|

    From the cursor, content information received from the editor (on cursor or text change),
    compute the editEvent, where it will be sent to the backend, then narrowcast to
    the clients current editing the given shared document.

-}
handleEditorChange : FrontendModel -> Int -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
handleEditorChange model cursor content =
    let
        --_ =
        --    Debug.log "(cursor, content)" ( cursor, content )
        newOTDocument =
            let
                id =
                    Maybe.map .id model.currentDocument |> Maybe.withDefault "---"
            in
            { docId = id, cursor = cursor, content = content }

        -- |> Debug.log "OT NEW"
        userId =
            model.currentUser |> Maybe.map .id |> Maybe.withDefault "---"

        --oldDocument =
        --model.networkModel.serverState.document |> Debug.log "OT OLD"
        editEvent_ =
            NetworkModel.createEvent userId model.oTDocument newOTDocument

        -- |> Debug.log "OT EVENT"
    in
    ( { model | counter = model.counter + 1, oTDocument = newOTDocument }, Effect.Lamdera.sendToBackend (Types.PushEditorEvent editEvent_) )


addUserToCurrentEditorsOfDocument : Maybe User -> Document -> Document
addUserToCurrentEditorsOfDocument currentUser doc =
    case currentUser of
        Nothing ->
            doc

        Just user ->
            let
                oldEditorList =
                    doc.currentEditorList

                equal a b =
                    a.userId == b.userId

                editorItem : Document.EditorData
                editorItem =
                    -- TODO: need actual clients
                    { userId = user.id, username = user.username, clients = [] }

                currentEditorList =
                    if Predicate.documentIsMineOrSharedToMe (Just doc) currentUser then
                        Util.insertInListOrUpdate equal editorItem oldEditorList

                    else
                        oldEditorList

                updatedDoc =
                    if Predicate.documentIsMineOrSharedToMe (Just doc) currentUser then
                        { doc | status = Document.DSCanEdit, currentEditorList = currentEditorList }

                    else
                        { doc | status = Document.DSReadOnly }
            in
            updatedDoc


setToReadOnlyIfNoEditors : Document -> Document
setToReadOnlyIfNoEditors doc =
    if doc.currentEditorList == [] then
        { doc | status = Document.DSReadOnly }

    else
        doc


inputCursor : { position : Int, source : String } -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
inputCursor { position, source } model =
    if Document.numberOfEditors model.currentDocument > 1 && Predicate.permitExperimentalCollabEditing model.currentUser model.experimentalMode then
        handleCursor { position = position, source = source } model

    else
        ( model, Effect.Command.none )


inputText : FrontendModel -> Document.SourceTextRecord -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
inputText model { position, source } =
    if
        Document.numberOfEditors model.currentDocument
            > 1
            && Predicate.permitExperimentalCollabEditing model.currentUser model.experimentalMode
    then
        handleEditorChange model position source

    else
        inputText_ model source


inputText_ : FrontendModel -> String -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
inputText_ model str =
    let
        -- Push your values here.
        -- This is how we throttle saving the document
        ( debounce, debounceCmd ) =
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
        , messages = [ { txt = String.join ", " messages, status = MSYellow } ]
        , debounce = debounce
        , counter = model.counter + 1
        , documentDirty = True
      }
    , debounceCmd
    )


{-| Here is where documents get saved. This is done
at present every 300 milliseconds. Here is the path:

  - Frontend.Update.save
  - perform the task Saved in Frontend
  - this just makes the call 'Frontend.updateDoc model str'
  - which calls 'Frontend.updateDoc\_ model str'
  - which issues the command 'sendToBackend (SaveDocument newDocument)'
  - which calls 'Backend.Update.saveDocument model document'
  - which updates the documentDict with `Dict.insert document.id { document | modified = model.currentTime } model.documentDict`

This is way too complicated!

-}
debounceMsg : FrontendModel -> Debounce.Msg -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
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


save : String -> Command FrontendOnly ToBackend FrontendMsg
save s =
    Effect.Task.perform Types.Saved (Effect.Task.succeed s)


debounceConfig : Debounce.Config FrontendMsg
debounceConfig =
    { strategy = Debounce.soon Config.debounceSaveDocumentInterval
    , transform = Types.DebounceMsg
    }
