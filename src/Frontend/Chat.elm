module Frontend.Chat exposing (createGroup, setGroup)

import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Types


setGroup : Types.FrontendModel -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
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


createGroup : Types.FrontendModel -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
createGroup model =
    case model.currentUser of
        Nothing ->
            ( { model | chatDisplay = Types.TCGDisplay }, Effect.Command.none )

        Just user ->
            let
                newChatGroup =
                    { name = model.inputGroupName
                    , owner = user.username
                    , assistant = Just model.inputGroupAssistant
                    , members = model.inputGroupMembers |> String.split "," |> List.map String.trim
                    }
            in
            ( { model | chatDisplay = Types.TCGDisplay, currentChatGroup = Just newChatGroup }, Effect.Lamdera.sendToBackend (Types.InsertChatGroup newChatGroup) )
