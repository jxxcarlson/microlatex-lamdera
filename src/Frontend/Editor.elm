module Frontend.Editor exposing (open)

import Effect.Command
import Frontend.Update
import Types


open model =
    case model.currentDocument of
        Nothing ->
            ( { model | messages = [ { txt = "No document to open in editor", status = Types.MSWhite } ] }, Effect.Command.none )

        Just doc ->
            Frontend.Update.openEditor doc model
