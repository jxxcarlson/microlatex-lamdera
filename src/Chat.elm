module Chat exposing
    ( consolidate
    , getClients
    , initialGroup
    , insert
    , narrowCast
    , sendChatHistoryCmd
    )

import Dict
import Lamdera
import List.Extra
import Time
import Types exposing (ChatMsg(..))



-- CONSOLIDATE


consolidate : List Types.ChatMsg -> List Types.ChatMsg
consolidate messages =
    messages |> group |> concat


group : List Types.ChatMsg -> List ( Types.ChatMsg, List Types.ChatMsg )
group messages =
    List.Extra.groupWhile close messages


close : Types.ChatMsg -> Types.ChatMsg -> Bool
close mx1 mx2 =
    case ( mx1, mx2 ) of
        ( ChatMsg _ m1, ChatMsg _ m2 ) ->
            m1.sender == m2.sender && interval m1.date m2.date < 60

        _ ->
            False


interval : Time.Posix -> Time.Posix -> Float
interval t1 t2 =
    toFloat (Time.posixToMillis t2 - Time.posixToMillis t1) / 1000.0


concat : List ( Types.ChatMsg, List Types.ChatMsg ) -> List Types.ChatMsg
concat messageGroups =
    List.map concatGroup messageGroups


concatGroup : ( Types.ChatMsg, List Types.ChatMsg ) -> Types.ChatMsg
concatGroup ( firstMessage, rest ) =
    case firstMessage of
        JoinedChat _ _ ->
            firstMessage

        LeftChat _ _ ->
            firstMessage

        ChatMsg clientId chatMessage ->
            let
                firstText =
                    chatMessage.content

                remainingText =
                    List.map toString rest |> String.join " "

                content =
                    firstText ++ " " ++ remainingText
            in
            ChatMsg clientId
                { sender = chatMessage.sender
                , group = chatMessage.group
                , subject = chatMessage.subject
                , content = content
                , date = chatMessage.date
                }


toString : ChatMsg -> String
toString chatMsg =
    case chatMsg of
        JoinedChat _ _ ->
            ""

        LeftChat _ _ ->
            ""

        ChatMsg _ msg ->
            msg.content



-- NARROWCAST


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



-- HISTORY


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
