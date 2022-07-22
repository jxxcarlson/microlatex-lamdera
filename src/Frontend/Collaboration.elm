module Frontend.Collaboration exposing
    ( initializeNetworkModel
    , processEvent
    , resetNetworkModel
    , toggle
    )

import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OT as OT
import CollaborativeEditing.OTCommand as OTCommand
import Compiler.DifferentialParser
import Document
import Effect.Command
import Effect.Lamdera
import Types
import User


toggle model =
    case model.currentDocument of
        Nothing ->
            ( model, Effect.Command.none )

        Just doc ->
            case model.collaborativeEditing of
                False ->
                    ( model, Effect.Lamdera.sendToBackend (Types.InitializeNetworkModelsWithDocument doc) )

                True ->
                    ( model, Effect.Lamdera.sendToBackend (Types.ResetNetworkModelForDocument doc) )


initializeNetworkModel model networkModel =
    ( { model
        | collaborativeEditing = True
        , networkModel = networkModel
        , editCommand = { counter = model.counter, command = OTCommand.CMoveCursor 0 }
      }
    , Effect.Command.none
    )


resetNetworkModel model networkModel document =
    ( { model
        | collaborativeEditing = False
        , networkModel = networkModel
        , currentDocument = Just document
        , documents = Document.updateDocumentInList document model.documents
        , showEditor = False
      }
    , Effect.Command.none
    )


processEvent model event =
    let
        --_ =
        --    Debug.log "ProcessEvent" event
        newNetworkModel =
            --NetworkModel.updateFromBackend NetworkModel.applyEvent event model.networkModel
            NetworkModel.appendEvent event model.networkModel

        doc : OT.Document
        doc =
            NetworkModel.getLocalDocument newNetworkModel

        newEditRecord : Compiler.DifferentialParser.EditRecord
        newEditRecord =
            Compiler.DifferentialParser.init model.includedContent model.language doc.content

        editCommand =
            if User.currentUserId model.currentUser /= event.userId then
                -- FOR NOW: execute edits from other users (?? check on docId also?)
                { counter = model.counter, command = event |> OTCommand.toCommand }

            else if event.operation == OT.Delete 0 -1 then
                -- TODO: Why is this even happening?
                { counter = model.counter, command = OTCommand.CNoOp }

            else
                { counter = model.counter, command = OTCommand.CNoOp }
    in
    ( { model
        | editCommand = editCommand

        -- editorEvent = { counter = model.counter, cursor = cursor, event = editorEvent }
        -- TODO!!
        -- ,  eventQueue = Deque.pushFront event model.eventQueue
        , networkModel = newNetworkModel
        , editRecord = newEditRecord
      }
    , Effect.Command.none
    )
