module Frontend.Chat exposing (setGroup)

import Effect.Command
import Effect.Lamdera
import Types


setGroup model =
    case model.currentUser of
        Nothing ->
            ( model, Effect.Command.none )

        Just user ->
            let
                oldPreferences =
                    user.preferences

                revisedPreferences =
                    if String.trim model.inputGroup == "" then
                        { oldPreferences | group = Nothing }

                    else
                        { oldPreferences | group = Just (String.trim model.inputGroup) }

                revisedUser =
                    { user | preferences = revisedPreferences }

                ( updatedChatMessages, cmd ) =
                    ( [], Effect.Lamdera.sendToBackend (Types.SendChatHistory (String.trim model.inputGroup)) )

                --if Just (String.trim model.inputGroup) == oldPreferences.group then
                --    ( model.chatMessages, Cmd.none )
                --
                --else
                --    ( [], sendToBackend (SendChatHistory (String.trim model.inputGroup)) )
            in
            ( { model | currentUser = Just revisedUser, chatMessages = updatedChatMessages }, Effect.Command.batch [ cmd, Effect.Lamdera.sendToBackend (Types.UpdateUserWith revisedUser) ] )
