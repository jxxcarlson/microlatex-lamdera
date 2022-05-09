module CollaborativeEditing.NetworkModel2 exposing (..)

import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OT as OT
import Deque exposing (Deque)
import Dict exposing (Dict)
import Json.Encode as E
import List.Extra
import String.Extra
import Util


type alias Username =
    String


type alias DocId =
    String


{-|

    EditEvents are deduced from changes in {cursor, content} emitted by the
    text editor.

-}
type alias EditEvent =
    { cursorChange : Int, operations : List OT.Operation }


type alias LocalModel =
    { userData : UserData
    , pendingChanges : Deque EditEvent
    , sentChanges : List EditEvent
    , localDocument : OT.Document
    , revisions : List Revision
    }


type alias UserData =
    { username : Username, clientId : String }


type alias Revision =
    { revision : Int, doc : OT.Document }


type alias Server =
    { clients : Dict DocId (List UserData)
    , revisionLog : Dict DocId (List EditEvent)
    , pendingChanges : Dict DocId (Deque ( Username, EditEvent ))
    , documents : Dict DocId OT.Document
    }


type alias LocalState =
    { editor : OT.Document, localModel : LocalModel }


{-|

    1.

    Given: a list of OT.operation, representing user actions in the text editor
      - Update the editor (cursor, content) via using OT.apply
      - Compute the editEvent from the new and old versions of the editor

-}
applyEditorOperations : List OT.Operation -> LocalState -> ( LocalState, EditEvent )
applyEditorOperations operations model =
    let
        editor =
            OT.apply operations model.editor

        editEvent =
            createEvent model.editor editor
    in
    ( { model | editor = OT.apply operations model.editor }, editEvent )


{-|

    2.

-}
applyEventToLocalState : ( LocalState, EditEvent ) -> ( LocalState, EditEvent )
applyEventToLocalState ( state, editEvent ) =
    let
        model =
            state.localModel

        newModel =
            { model
                | pendingChanges = Deque.pushFront editEvent model.pendingChanges
                , localDocument = applyEvent editEvent model.localDocument
            }
    in
    ( { state | localModel = newModel }, editEvent )


{-|

    3 . Send local changes to server

-}
sendChanges : ( LocalState, Server ) -> ( LocalState, Server )
sendChanges ( localState, server ) =
    let
        getEvent : LocalModel -> ( LocalModel, Maybe EditEvent )
        getEvent localModel =
            case Deque.popBack localModel.pendingChanges of
                ( Nothing, deque ) ->
                    ( localModel, Nothing )

                ( Just event, deque ) ->
                    ( { localModel | pendingChanges = deque, sentChanges = event :: localModel.sentChanges }, Just event )

        ( model, mEvent ) =
            getEvent localState.localModel

        username =
            localState.localModel.userData.username

        docId =
            localState.localModel.localDocument.docId

        newServer =
            case mEvent of
                Nothing ->
                    server

                Just event ->
                    { server | pendingChanges = insertEvent docId ( username, event ) server.pendingChanges }
    in
    ( { localState | localModel = model }, newServer )


{-|

        4. At Server: Apply one Change

-}
updateServer : Server -> Server
updateServer server =
    server


insertEvent : DocId -> ( Username, EditEvent ) -> Dict DocId (Deque ( Username, EditEvent )) -> Dict DocId (Deque ( Username, EditEvent ))
insertEvent docId ( username, editEvent ) dict =
    Dict.update docId (Util.liftToMaybe (updateDeque ( username, editEvent ))) dict


updateDeque : ( Username, EditEvent ) -> Deque ( Username, EditEvent ) -> Deque ( Username, EditEvent )
updateDeque ( username, event ) deque =
    Deque.pushFront ( username, event ) deque


applyEvent : EditEvent -> OT.Document -> OT.Document
applyEvent event doc =
    OT.apply event.operations doc


createEvent : OT.Document -> OT.Document -> EditEvent
createEvent oldDocument newDocument =
    let
        cursorChange =
            newDocument.cursor - oldDocument.cursor

        _ =
            Debug.log "!! (old, new, dp)" ( oldDocument.cursor, newDocument.cursor, cursorChange )

        operations : List OT.Operation
        operations =
            OT.findOps oldDocument newDocument
    in
    { cursorChange = cursorChange, operations = operations } |> Debug.log "!! CREATE EVENT"


deleteAt i n str =
    String.left (n + 1) str ++ String.dropLeft (i + n + 1) str



-- OPERATIONS
-- INITIALIZERS


setSharedDocument : DocId -> String -> OT.Document
setSharedDocument docId source =
    { content = source
    , cursor = 0
    , docId = docId
    }


setLocalState : DocId -> UserData -> String -> LocalState
setLocalState docId userData source =
    { editor = setSharedDocument docId source, localModel = setLocalModel docId userData source }


setLocalModel : DocId -> UserData -> String -> LocalModel
setLocalModel docId userData source =
    let
        doc =
            setSharedDocument docId source
    in
    { userData = userData
    , pendingChanges = Deque.empty
    , sentChanges = []
    , localDocument = doc
    , revisions = { revision = 0, doc = doc } :: []
    }


startSession : DocId -> List UserData -> String -> Server -> Server
startSession docId userList source server =
    { server
        | clients = Dict.insert docId userList server.clients
        , revisionLog = Dict.insert docId [] server.revisionLog
        , pendingChanges = Dict.insert docId Deque.empty server.pendingChanges
        , documents = Dict.insert docId (setSharedDocument docId source) server.documents
    }


removeSession : DocId -> Server -> Server
removeSession docId server =
    { server
        | clients = Dict.remove docId server.clients
        , revisionLog = Dict.remove docId server.revisionLog
        , pendingChanges = Dict.remove docId server.pendingChanges
        , documents = Dict.remove docId server.documents
    }


initialServer : Server
initialServer =
    { clients = Dict.empty
    , revisionLog = Dict.empty
    , pendingChanges = Dict.empty
    , documents = Dict.empty
    }



--fii =
--    ( { editor = { content = "abc", cursor = 3, docId = "doc" }
--      , localModel = { localDocument = { content = "abc", cursor = 3, docId = "doc" }, pendingChanges = Deque { front = [], rear = [], sizeF = 0, sizeR = 0 }, revisions = [ { doc = { content = "", cursor = 0, docId = "doc" }, revision = 0 } ]
--      , sentChanges = [], username = "Andrew " }
--      }
--    , { documents = Dict.fromList [ ( "doc", { content = "", cursor = 0, docId = "doc" } ) ]
--    , pendingChanges = Dict.fromList [ ( "doc", Deque { front = [ ( "Andrew ", { cursorChange = 3, operations = [ Insert 0 "abc" ] } ) ], rear = [], sizeF = 1, sizeR = 0 } ) ]
--    , revisionLog = Dict.fromList [ ( "doc", [] ) ] }
--    )
