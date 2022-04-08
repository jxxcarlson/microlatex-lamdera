module View.Chat exposing (..)

import Browser.Dom as Dom
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (autofocus, id, placeholder, style, type_, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as D
import Lamdera
import Task
import Types exposing (..)


chatInput : FrontendModel -> (String -> FrontendMsg) -> Html FrontendMsg
chatInput model msg =
    input
        ([ id "message-input"
         , type_ "text"
         , onInput msg
         , onEnter Types.MessageSubmitted
         , placeholder model.messageFieldContent
         , value model.messageFieldContent
         , style "width" "300px"
         , autofocus True
         ]
            ++ fontStyles
        )
        []


viewMessage : ChatMsg -> Html msg
viewMessage msg =
    case msg of
        Types.JoinedChat clientId username ->
            div [ style "font-style" "italic" ] [ text <| username ++ " joined the chat" ]

        Types.LeftChat clientId username ->
            div [ style "font-style" "italic" ] [ text <| username ++ " left the chat" ]

        Types.ChatMsg clientId message ->
            div [] [ text <| "[" ++ String.left 6 clientId ++ "]: " ++ message.content ]


fontStyles : List (Html.Attribute msg)
fontStyles =
    [ style "font-family" "Helvetica", style "font-size" "14px", style "line-height" "1.5" ]


scrollChatToBottom : Cmd FrontendMsg
scrollChatToBottom =
    Dom.getViewportOf "message-box"
        |> Task.andThen (\info -> Dom.setViewportOf "message-box" 0 info.scene.height)
        |> Task.attempt (\_ -> Types.FENoOp)


focusMessageInput : Cmd FrontendMsg
focusMessageInput =
    Task.attempt (always Types.FENoOp) (Dom.focus "message-input")


onEnter : FrontendMsg -> Html.Attribute FrontendMsg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                D.succeed msg

            else
                D.fail "not ENTER"
    in
    on "keydown" (keyCode |> D.andThen isEnter)
