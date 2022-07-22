module Frontend.Scheduler exposing (schedule)

import Config
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Time
import Frontend.Authentication
import Types


schedule : Types.FrontendModel -> Effect.Time.Posix -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
schedule model newTime =
    let
        lastInteractionTimeMilliseconds =
            model.lastInteractionTime |> Effect.Time.posixToMillis

        currentTimeMilliseconds =
            model.currentTime |> Effect.Time.posixToMillis

        elapsedSinceLastInteractionSeconds =
            (currentTimeMilliseconds - lastInteractionTimeMilliseconds) // 1000

        activeEditor =
            case model.activeEditor of
                Nothing ->
                    Nothing

                Just { activeAt } ->
                    if Effect.Time.posixToMillis activeAt < (Effect.Time.posixToMillis model.currentTime - (Config.editSafetyInterval * 1000)) then
                        Nothing

                    else
                        model.activeEditor

        newTimer =
            case model.currentUser of
                Nothing ->
                    model.timer + 1

                Just _ ->
                    0
    in
    -- If the lastInteractionTime has not been updated since init, do so now.
    if model.lastInteractionTime == Effect.Time.millisToPosix 0 && model.currentUser /= Nothing then
        ( { model | timer = newTimer, activeEditor = activeEditor, currentTime = newTime, lastInteractionTime = newTime }, Effect.Command.none )

    else if elapsedSinceLastInteractionSeconds >= Config.automaticSignoutLimit && model.currentUser /= Nothing then
        Frontend.Authentication.signOut { model | timer = newTimer, currentTime = newTime }

    else
        ( { model | timer = newTimer, activeEditor = activeEditor, currentTime = newTime }, Effect.Command.none )
