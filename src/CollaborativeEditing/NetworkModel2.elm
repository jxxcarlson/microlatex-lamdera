module CollaborativeEditing.NetworkModel2 exposing (..)

import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OT as OT
import Deque exposing (Deque)
import Dict exposing (Dict)
import Json.Encode as E
import List.Extra
import String.Extra


type alias UserId =
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
    { pendingChanges : Deque EditEvent
    , sentChanges : List EditEvent
    , localDocument : OT.Document
    , revisions : List Revision
    }


type alias Revision =
    { revision : Int, doc : OT.Document }


type alias CollaborationServer =
    { revisionLog : Dict DocId (List EditEvent)
    , pendingChanges : Dict DocId (List EditEvent)
    , documents : Dict DocId OT.Document
    }


type alias LocalState =
    { editor : OT.Document, localModel : LocalModel }


{-|

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


setLocalState : DocId -> String -> LocalState
setLocalState docId source =
    { editor = setSharedDocument docId source, localModel = setLocalModel docId source }


setLocalModel : DocId -> String -> LocalModel
setLocalModel docId source =
    let
        doc =
            setSharedDocument docId source
    in
    { pendingChanges = Deque.empty
    , sentChanges = []
    , localDocument = doc
    , revisions = { revision = 0, doc = doc } :: []
    }


startSession : DocId -> String -> CollaborationServer -> CollaborationServer
startSession docId source server =
    { server
        | revisionLog = Dict.insert docId [] server.revisionLog
        , pendingChanges = Dict.insert docId [] server.pendingChanges
        , documents = Dict.insert docId (setSharedDocument docId source) server.documents
    }


removeSession : DocId -> CollaborationServer -> CollaborationServer
removeSession docId server =
    { server
        | revisionLog = Dict.remove docId server.revisionLog
        , pendingChanges = Dict.remove docId server.pendingChanges
        , documents = Dict.remove docId server.documents
    }


initialCollobarationServer : CollaborationServer
initialCollobarationServer =
    { revisionLog = Dict.empty
    , pendingChanges = Dict.empty
    , documents = Dict.empty
    }
