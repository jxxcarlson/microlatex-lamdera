module Frontend.Message exposing (received, submitted)

import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Types
import View.Chat


submitted : Types.FrontendModel -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
submitted model =
    let
        chatMessage =
            { sender = model.currentUser |> Maybe.map .username |> Maybe.withDefault "anon"
            , group = model.inputGroup
            , subject = ""
            , content = model.chatMessageFieldContent
            , date = model.currentTime
            }
    in
    ( { model | chatMessageFieldContent = "", messages = model.messages }
    , Effect.Command.batch
        [ Effect.Lamdera.sendToBackend (Types.ChatMsgSubmitted chatMessage)
        , View.Chat.focusMessageInput
        , View.Chat.scrollChatToBottom
        ]
    )


received model message =
    let
        newMessages =
            if List.member message.status [ Types.MSRed, Types.MSYellow, Types.MSGreen ] then
                [ message ]

            else
                model.messages
    in
    if message.txt == "Sorry, password and username don't match" then
        ( { model | inputPassword = "", messages = newMessages }, Effect.Command.none )

    else
        ( { model | messages = newMessages }, Effect.Command.none )
