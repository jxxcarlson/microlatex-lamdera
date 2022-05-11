module View.Chat exposing (focusMessageInput, scrollChatToBottom, view)

import Browser.Dom as Dom
import Chat
import DateTimeUtility
import Element as E
import Element.Background as Background
import Element.Font as Font
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (autofocus, id, placeholder, style, type_, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as D
import Task
import Time
import Types exposing (..)
import Util
import View.Button
import View.Color as Color
import View.Geometry as Geometry
import View.Input
import View.Utility


view : FrontendModel -> E.Element FrontendMsg
view model =
    E.column
        [ E.spacing 0
        , Background.color Color.black
        , E.padding 1

        --, E.height (E.px (model.windowHeight - 150))
        , E.height (E.px <| Geometry.appHeight model - 100)
        ]
        [ viewMessages model
        , viewCurrentGroup model
        , editGroup model
        ]


viewMessages model =
    case model.chatDisplay of
        Types.TCGDisplay ->
            E.el [ E.paddingEach { left = 0, right = 0, top = 18, bottom = 8 } ] (viewMessages_ (model.windowHeight - 500) model)

        TCGShowInputForm ->
            E.el [ E.paddingEach { left = 0, right = 0, top = 18, bottom = 8 } ] (viewMessages_ (model.windowHeight - 770) model)


viewCurrentGroup model =
    case model.chatDisplay of
        Types.TCGDisplay ->
            E.column [ E.spacing 8, E.paddingXY 10 10 ]
                [ E.row [ E.paddingEach { left = 0, right = 0, top = 0, bottom = 0 }, E.spacing 8 ]
                    [ View.Button.makeCurrentGroupPreferred, View.Input.group model ]
                , viewChatGroup model
                , E.row [ E.spacing 8 ] [ View.Button.setChatCreate model, View.Button.clearChatHistory ]
                ]

        TCGShowInputForm ->
            E.none


editGroup model =
    E.el [ E.paddingXY 18 18 ]
        (case model.chatDisplay of
            Types.TCGDisplay ->
                E.none

            Types.TCGShowInputForm ->
                E.row [ E.spacing 12 ] [ createChatGroup model ]
        )


viewChatGroup : FrontendModel -> E.Element FrontendMsg
viewChatGroup model =
    case model.currentChatGroup of
        Nothing ->
            E.column
                [ E.paddingEach { left = 18, right = 0, top = 18, bottom = 0 }
                , E.height (E.px 160)
                , E.width (E.px 325)
                , Background.color Color.veryPaleBlue
                , Font.size 14
                , E.spacing 12
                ]
                [ E.el [] (E.text "Enter a group name above or create a group")
                , E.row [ E.spacing 18 ] [ View.Button.setChatCreate model ]
                ]

        Just group ->
            E.column
                [ E.paddingEach { left = 8, right = 0, top = 8, bottom = 0 }
                , E.height (E.px 90)
                , E.width (E.px 363)
                , Background.color Color.veryPaleBlue
                , Font.size 14
                , E.spacing 12
                ]
                [ row "Group: " group.name
                , row "Members: " (String.join ", " group.members)
                ]


createChatGroup : FrontendModel -> E.Element FrontendMsg
createChatGroup model =
    case model.currentUser of
        Nothing ->
            E.none

        Just user ->
            E.column
                [ E.paddingXY 12 12
                , E.height (E.px 420)
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


viewMessages_ : Int -> FrontendModel -> E.Element FrontendMsg
viewMessages_ h model =
    E.column [ E.paddingXY 10 0, E.spacing 8 ]
        [ model.chatMessages
            |> List.reverse
            |> List.map (viewMessage model.zone)
            |> E.column
                [ View.Utility.htmlId "message-box"
                , E.height (E.px h)
                , E.width (E.px 360)
                , E.spacing 12
                , E.scrollbarY
                , Background.color Color.transparentBlue
                , E.paddingXY 6 16
                ]

        , chatInput model MessageFieldChanged |> E.html

        , button (onClick MessageSubmitted :: style "width" "363px" :: style "height" "32px" :: style "color" "#fff" :: style "background-color" "#888" :: fontStyles) [ text "Send" ] |> E.html
        ]


chatInput : FrontendModel -> (String -> FrontendMsg) -> Html FrontendMsg
chatInput model msg =
    input
        ([ id "message-input"
         , type_ "text"
         , onInput msg
         , style "height" "30px"
         , onEnter Types.MessageSubmitted
         , placeholder model.chatMessageFieldContent
         , value model.chatMessageFieldContent
         , style "width" "353px"
         , autofocus True
         ]
            ++ fontStyles
        )
        []


viewMessage : Time.Zone -> ChatMsg -> E.Element msg
viewMessage zone msg =
    case msg of
        Types.JoinedChat clientId username ->
            E.paragraph [ Font.italic ] [ E.text <| username ++ " joined the chat" ]

        Types.LeftChat clientId username ->
            E.paragraph [ Font.italic ] [ E.text <| username ++ " left the chat" ]

        Types.ChatMsg clientId message ->
            E.paragraph [ E.width (E.px 340) ] [ E.el [ Font.bold ] (E.text <| "[" ++ message.sender ++ " (" ++ message.group ++ ") " ++ DateTimeUtility.toString zone message.date ++ "]: "), E.text <| message.content ]


fontStyles : List (Html.Attribute msg)
fontStyles =
    [ style "font-family" "Helvetica", style "font-size" "14px", style "line-height" "1.5" ]


scrollChatToBottom : Cmd FrontendMsg
scrollChatToBottom =
    Dom.getViewportOf "message-box"
        |> Task.andThen (\info -> Dom.setViewportOf "message-box" 0 info.scene.height)
        |> Task.attempt (\_ -> Types.FENoOp)



-- |> Task.andThen (\_ -> Util.delay 100 Types.ScrollChatToBottom)


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
