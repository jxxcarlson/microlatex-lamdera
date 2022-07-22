module Backend.Chat exposing (handleChatMsg, handlePing, msgSubmitted)

import Chat
import Chat.Message
import Dict
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import Types exposing (BackendModel, BackendMsg, ToFrontend)
import Util


msgSubmitted model message =
    if String.left 2 message.content == "!!" then
        model
            |> Util.apply (handleChatMsg message)
            |> Util.andThenApply (handlePing message) Command.batch

    else
        model |> Util.apply (handleChatMsg message)


handleChatMsg : Chat.Message.ChatMessage -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleChatMsg message model =
    ( { model | chatDict = Chat.Message.insert message model.chatDict }, Command.batch (Chat.narrowCast model message) )


userMessageFromChatMessage : Chat.Message.ChatMessage -> String -> Types.UserMessage
userMessageFromChatMessage { sender, content } recipient =
    { from = sender
    , to = recipient
    , subject = "Ping"
    , content =
        if String.left 2 content == "!!" then
            String.dropLeft 2 content

        else
            content
    , show = []
    , info = ""
    , action = Types.FENoOp
    , actionOnFailureToDeliver = Types.FANoOp
    }


handlePing : Chat.Message.ChatMessage -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handlePing message model =
    let
        groupMembers =
            Dict.get message.group model.chatGroupDict
                |> Maybe.map .members
                |> Maybe.withDefault []
                |> List.filter (\name -> name /= message.sender)

        messages =
            List.map (userMessageFromChatMessage message) groupMembers

        commands : List (Command BackendOnly ToFrontend BackendMsg)
        commands =
            List.map (\m -> deliverUserMessageCmd model m) messages
    in
    ( model, Command.batch commands )


deliverUserMessageCmd : BackendModel -> Types.UserMessage -> Command BackendOnly ToFrontend BackendMsg
deliverUserMessageCmd model usermessage =
    case Dict.get usermessage.to model.connectionDict of
        Nothing ->
            Command.none

        Just connectionData ->
            let
                clientIds =
                    List.map .client connectionData

                commands =
                    List.map (\clientId_ -> Effect.Lamdera.sendToFrontend clientId_ (Types.UserMessageReceived usermessage)) clientIds
            in
            Command.batch commands
