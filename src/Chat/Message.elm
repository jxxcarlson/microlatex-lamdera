module Chat.Message exposing (ChatMessage, consolidate, consolidateOne, consolidateTwo, insert)

import Dict exposing (Dict)
import List.Extra
import Time


type alias ChatMessage =
    { sender : String
    , group : String
    , subject : String
    , content : String
    , date : Time.Posix
    }


type alias GroupName =
    String


insert : ChatMessage -> Dict GroupName (List ChatMessage) -> Dict GroupName (List ChatMessage)
insert message dict =
    case Dict.get message.group dict of
        Nothing ->
            dict

        Just messageList ->
            Dict.insert message.group (consolidateOne message messageList) dict


consolidateOne : ChatMessage -> List ChatMessage -> List ChatMessage
consolidateOne message list =
    case list of
        [] ->
            [ message ]

        first :: rest ->
            if close message first then
                let
                    updatedFirst =
                        { sender = first.sender
                        , group = first.group
                        , subject = first.subject
                        , content = first.content ++ " " ++ message.content
                        , date = first.date
                        }
                in
                updatedFirst :: rest

            else
                message :: first :: rest


consolidateTwo : ChatMessage -> ChatMessage -> Maybe ChatMessage
consolidateTwo message1 message2 =
    if close message1 message2 then
        let
            updatedMessage =
                { sender = message1.sender
                , group = message1.group
                , subject = message1.subject
                , content = message2.content ++ " " ++ message1.content
                , date = message1.date
                }
        in
        Just updatedMessage

    else
        Nothing


timeOf : ChatMessage -> Int
timeOf msg =
    msg.date |> Time.posixToMillis


consolidate : List ChatMessage -> List ChatMessage
consolidate messages =
    messages |> List.sortBy timeOf |> group |> concat


group : List ChatMessage -> List ( ChatMessage, List ChatMessage )
group messages =
    let
        out =
            List.Extra.groupWhile close messages
    in
    out


close : ChatMessage -> ChatMessage -> Bool
close mx1 mx2 =
    mx1.sender == mx2.sender && (interval mx2.date mx1.date < 60.0)


interval : Time.Posix -> Time.Posix -> Float
interval t1 t2 =
    toFloat (Time.posixToMillis t2 - Time.posixToMillis t1) / 1000.0


concat : List ( ChatMessage, List ChatMessage ) -> List ChatMessage
concat messageGroups =
    List.map concatGroup messageGroups


concatGroup : ( ChatMessage, List ChatMessage ) -> ChatMessage
concatGroup ( firstMessage, rest ) =
    let
        firstText =
            firstMessage.content

        remainingText =
            List.map toString rest |> String.join " "

        content =
            firstText ++ " " ++ remainingText
    in
    { sender = firstMessage.sender
    , group = firstMessage.group
    , subject = firstMessage.subject
    , content = content
    , date = firstMessage.date
    }


toString : ChatMessage -> String
toString msg =
    msg.content
