module Frontend.Collaboration exposing (initializeNetworkModel, toggle)

import CollaborativeEditing.OTCommand as OTCommand
import Effect.Command
import Effect.Lamdera
import Types


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
