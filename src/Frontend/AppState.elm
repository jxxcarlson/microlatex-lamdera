module Frontend.AppState exposing (set)

import Effect.Command
import Effect.Lamdera
import Types


set model appMode =
    let
        cmd =
            case appMode of
                Types.UserMode ->
                    Effect.Command.none

                Types.AdminMode ->
                    Effect.Lamdera.sendToBackend Types.GetUserList
    in
    ( { model | appMode = appMode }, Effect.Command.batch [ cmd ] )
