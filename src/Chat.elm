module Chat exposing
    ( getClients
    , initialGroup
    , insert
    , narrowCast
    , sendChatHistoryCmd
    )

import Dict
import Lamdera
import Types


narrowCast : Types.BackendModel -> Types.ChatMessage -> List (Cmd backendMsg)
narrowCast model message =
    let
        groupMembers =
            Dict.get message.group model.chatGroupDict |> Maybe.map .members |> Maybe.withDefault []

        clientIds =
            List.map (\username -> getClients username model.connectionDict) groupMembers |> List.concat

        commands : List (Cmd backendMsg)
        commands =
            List.map (\clientId_ -> Lamdera.sendToFrontend clientId_ (Types.ChatMessageReceived (Types.ChatMsg clientId_ message))) clientIds
    in
    commands


sendChatHistoryCmd groupName model clientId =
    let
        chatMessages : List Types.ChatMessage
        chatMessages =
            Dict.get groupName model.chatDict |> Maybe.withDefault []

        cmds : List (Cmd backendMsg)
        cmds =
            List.map (narrowCast model) chatMessages |> List.concat
    in
    Cmd.batch (Lamdera.sendToFrontend clientId Types.GotChatHistory :: cmds)


getClients : Types.Username -> Types.ConnectionDict -> List Lamdera.ClientId
getClients username dict =
    Dict.get username dict |> Maybe.map (List.map .client) |> Maybe.withDefault []


insert : Types.ChatMessage -> Types.ChatDict -> Types.ChatDict
insert message chatDict =
    case Dict.get message.group chatDict of
        Nothing ->
            Dict.insert message.group [ message ] chatDict

        Just messages ->
            Dict.insert message.group (message :: messages) chatDict


initialGroup : Types.ChatGroup
initialGroup =
    { name = "test"
    , members = [ "jxxcarlson", "mario", "aristotle" ]
    , owner = "jxxcarlson"
    , assistant = Nothing
    }
