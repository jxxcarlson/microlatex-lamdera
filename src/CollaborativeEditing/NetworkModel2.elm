module CollaborativeEditing.NetworkModel2 exposing (..)

import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OT as OT
import CollaborativeEditing.Types
    exposing
        ( DocId
        , EditEvent
        , Msg(..)
        , Username
        )
import Deque exposing (Deque)
import Dict exposing (Dict)
import Json.Encode as E
import List.Extra
import String.Extra
import Util


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
applyEditorOperations operations localState =
    let
        editor =
            OT.apply operations localState.editor

        editEvent =
            createEvent localState.editor editor
    in
    ( { localState | editor = OT.apply operations localState.editor }, editEvent )


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

    Send one pending change if the sent changes list is empty.
    Note that changes are moved from the sent changes list
    when they are acknowledged by the server

-}
sendChanges : LocalState -> ( LocalState, Msg )
sendChanges localState =
    if List.isEmpty localState.localModel.sentChanges then
        sendChanges_ localState

    else
        ( localState, CENoOp )


{-|

    3b. Send local changes to server

-}
sendChanges_ : LocalState -> ( LocalState, Msg )
sendChanges_ localState =
    let
        getEvent : LocalModel -> ( LocalModel, Msg )
        getEvent localModel =
            case Deque.popBack localModel.pendingChanges of
                ( Nothing, _ ) ->
                    ( localModel, CENoOp )

                ( Just event, deque ) ->
                    ( { localModel | pendingChanges = deque, sentChanges = event :: localModel.sentChanges }
                    , ProcessEvent localModel.userData.username event
                    )

        ( model, mEvent ) =
            getEvent localState.localModel
    in
    ( { localState | localModel = model }, mEvent )


{-|

        4. At Server: Apply one change

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


setLocalState : DocId -> String -> UserData -> LocalState
setLocalState docId source userData =
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
