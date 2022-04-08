module View.Chat exposing (view)

import Browser.Dom as Dom
import Element as E
import Element.Background as Background
import Element.Font as Font
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (autofocus, id, placeholder, style, type_, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as D
import Task
import Types exposing (..)
import View.Button
import View.Color as Color
import View.Input


view : FrontendModel -> E.Element FrontendMsg
view model =
    E.column [ E.spacing 12, Background.color Color.black, E.padding 1 ]
        [ case model.chatDisplay of
            Types.TCGDisplay ->
                E.el [ E.paddingEach { left = 0, right = 0, top = 18, bottom = 8 } ] (view_ model)

            TCGShowInputForm ->
                E.none
        , case model.chatDisplay of
            Types.TCGDisplay ->
                E.row [ E.paddingEach { left = 8, right = 0, top = 0, bottom = 0 }, E.spacing 8 ] [ View.Input.group model ]

            TCGShowInputForm ->
                E.none
        , E.el [ E.paddingXY 18 18 ]
            (case model.chatDisplay of
                Types.TCGDisplay ->
                    viewChatGroup model

                Types.TCGShowInputForm ->
                    createChatGroup model
            )
        ]


viewChatGroup : FrontendModel -> E.Element FrontendMsg
viewChatGroup model =
    case model.currentChatGroup of
        Nothing ->
            E.column
                [ E.paddingEach { left = 18, right = 0, top = 18, bottom = 0 }
                , E.height (E.px 160)
                , E.width (E.px 340)
                , Background.color Color.veryPaleBlue
                , Font.size 14
                , E.spacing 12
                ]
                [ E.el [] (E.text "Enter a group name above or create a group")
                , E.row [ E.spacing 18 ] [ View.Button.setChatCreate model ]
                ]

        Just group ->
            E.column
                [ E.paddingEach { left = 18, right = 0, top = 18, bottom = 0 }
                , E.height (E.px 160)
                , E.width (E.px 340)
                , Background.color Color.veryPaleBlue
                , Font.size 14
                , E.spacing 12
                ]
                [ row "Group name: " group.name
                , row "Admin: " group.owner
                , row "Assistant: " (Maybe.withDefault "none" group.assistant)
                , row "Members: " (String.join ", " group.members)
                , E.row [ E.spacing 18 ] [ View.Button.setChatDisplay model, View.Button.setChatCreate model ]
                ]


createChatGroup : FrontendModel -> E.Element FrontendMsg
createChatGroup model =
    case model.currentUser of
        Nothing ->
            E.none

        Just user ->
            E.column
                [ E.paddingXY 12 12
                , E.height (E.px 460)
                , E.width (E.px 340)
                , Background.color Color.veryPaleBlue
                , Font.size 14
                , E.spacing 12
                ]
                [ column "Group Name" (View.Input.groupName 320 model)
                , row "Admin: " user.username
                , column "Assistant: " (View.Input.groupAssistant 320 model)
                , column "Members: " (View.Input.groupMembers 320 150 model)
                , E.row [ E.spacing 18 ] [ View.Button.setChatDisplay model, View.Button.createChatGroup ]
                ]


column : String -> E.Element FrontendMsg -> E.Element FrontendMsg
column label element =
    E.column [ E.width (E.px 300), E.spacing 12 ] [ E.el [ Font.bold ] (E.text label), element ]


row : String -> String -> E.Element FrontendMsg
row label content =
    E.paragraph [ E.width (E.px 300), E.spacing 12 ] [ E.el [ Font.bold ] (E.text label), E.text content ]


view_ : FrontendModel -> E.Element FrontendMsg
view_ model =
    div (style "padding" "10px" :: fontStyles)
        [ model.chatMessages
            |> List.reverse
            |> List.map viewMessage
            |> div
                [ id "message-box"
                , style "height" "400px"
                , style "overflow" "auto"
                , style "margin-bottom" "8px"
                , style "background-color" "#d9e2ff"
                , style "padding" "6px"
                ]
        , chatInput model MessageFieldChanged
        , button (onClick MessageSubmitted :: fontStyles) [ text "Send" ]
        ]
        |> E.html


chatInput : FrontendModel -> (String -> FrontendMsg) -> Html FrontendMsg
chatInput model msg =
    input
        ([ id "message-input"
         , type_ "text"
         , onInput msg
         , onEnter Types.MessageSubmitted
         , placeholder model.chatMessageFieldContent
         , value model.chatMessageFieldContent
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
            div [] [ text <| "[" ++ message.sender ++ "]: " ++ message.content ]


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
