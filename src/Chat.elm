module Chat exposing
    ( consolidate
    , consolidateOne
    , getClients
    , initialGroup
    , insert
    , narrowCast
    , sendChatHistoryCmd
    )

import Chat.Message
import Dict
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera
import Effect.Time
import List.Extra
import Types exposing (ChatMsg(..), ToFrontend)


consolidateOne : ChatMsg -> List ChatMsg -> List ChatMsg
consolidateOne msg list =
    case msg of
        JoinedChat _ _ ->
            msg :: list

        LeftChat _ _ ->
            msg :: list

        ChatMsg _ message1 ->
            case list of
                [] ->
                    [ msg ]

                first :: rest ->
                    case first of
                        JoinedChat _ _ ->
                            msg :: first :: rest

                        LeftChat _ _ ->
                            msg :: first :: rest

                        ChatMsg a message2 ->
                            case Chat.Message.consolidateTwo message1 message2 of
                                Nothing ->
                                    msg :: list

                                Just consolidated ->
                                    ChatMsg a consolidated :: rest


timeOf : ChatMsg -> Int
timeOf msg =
    case msg of
        JoinedChat _ _ ->
            0

        LeftChat _ _ ->
            0

        ChatMsg _ data ->
            data.date |> Effect.Time.posixToMillis


consolidate : List Types.ChatMsg -> List Types.ChatMsg
consolidate messages =
    messages |> List.sortBy timeOf |> group |> concat


group : List Types.ChatMsg -> List ( Types.ChatMsg, List Types.ChatMsg )
group messages =
    let
        out =
            List.Extra.groupWhile close messages
    in
    out


close : Types.ChatMsg -> Types.ChatMsg -> Bool
close mx1 mx2 =
    case ( mx1, mx2 ) of
        ( ChatMsg _ m1, ChatMsg _ m2 ) ->
            -- m1.sender == m2.sender && interval m1.date m2.date < 60
            m1.sender == m2.sender

        _ ->
            False


interval : Effect.Time.Posix -> Effect.Time.Posix -> Float
interval t1 t2 =
    toFloat (Effect.Time.posixToMillis t2 - Effect.Time.posixToMillis t1) / 1000.0


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


narrowCast : Types.BackendModel -> Chat.Message.ChatMessage -> List (Command BackendOnly Types.ToFrontend backendMsg)
narrowCast model message =
    let
        groupMembers =
            Dict.get message.group model.chatGroupDict |> Maybe.map .members |> Maybe.withDefault []

        clientIds =
            List.map (\username -> getClients username model.connectionDict) groupMembers |> List.concat

        commands : List (Command BackendOnly Types.ToFrontend backendMsg)
        commands =
            List.map (\clientId_ -> Effect.Lamdera.sendToFrontend clientId_ (Types.ChatMessageReceived (Types.ChatMsg clientId_ message))) clientIds
    in
    commands



-- HISTORY


sendChatHistoryCmd groupName model =
    let
        history : List Types.ChatMsg
        history =
            Dict.get groupName model.chatDict |> Maybe.withDefault [] |> List.map (\m -> ChatMsg ("0" |> Effect.Lamdera.clientIdFromString) m)

        groupMembers =
            Dict.get groupName model.chatGroupDict |> Maybe.map .members |> Maybe.withDefault []

        clientIds =
            List.map (\username -> getClients username model.connectionDict) groupMembers |> List.concat

        cmds : List (Command BackendOnly ToFrontend backendMsg)
        cmds =
            List.map (\clientId_ -> Effect.Lamdera.sendToFrontend clientId_ (Types.GotChatHistory history)) clientIds
    in
    Command.batch cmds


getClients : Types.Username -> Types.ConnectionDict -> List Effect.Lamdera.ClientId
getClients username dict =
    Dict.get username dict |> Maybe.map (List.map .client) |> Maybe.withDefault []


insert : Chat.Message.ChatMessage -> Types.ChatDict -> Types.ChatDict
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
