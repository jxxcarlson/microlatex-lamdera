module Frontend.Collaboration exposing (toggle)

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
