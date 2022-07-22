module Backend.Util exposing (andThenApply, apply)

import Effect.Command as Command exposing (BackendOnly, Command)
import Types exposing (BackendModel, BackendMsg, ToFrontend)


apply :
    (BackendModel -> ( BackendModel, Command restriction toMsg BackendMsg ))
    -> BackendModel
    -> ( BackendModel, Command restriction toMsg BackendMsg )
apply f model =
    f model


andThenApply :
    (BackendModel -> ( BackendModel, Command restriction toMsg BackendMsg ))
    -> ( BackendModel, Command restriction toMsg BackendMsg )
    -> ( BackendModel, Command restriction toMsg BackendMsg )
andThenApply f ( model, cmd ) =
    let
        ( model2, cmd2 ) =
            f model
    in
    ( model2, Command.batch [ cmd, cmd2 ] )
