module View.NetworkMonitor exposing (view)

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
import NetworkModel
import Task
import Time
import Types exposing (..)
import Util
import View.Button
import View.Color as Color
import View.Input
import View.Utility


view model =
    case model.popupState of
        NetworkMonitorPopup ->
            let
                dx = if model.showEditor then 950 else 700
            in
            E.column [E.width (E.px 400)
            , E.height (E.px 560)
            , Background.color Color.paleBlue, Font.size 14
            , E.moveUp 580, E.moveRight dx
            , E.spacing 12
            , E.paddingXY 20 20]

            [E.row [E.width (E.px 360)] [E.text "NetworkMonitor", E.el [E.alignRight] (View.Button.dismissPopup)]
            , E.row [E.spacing 12] [View.Input.editorCommand 200 model, View.Button.runCommand]
            , E.text <| "Source length: " ++ (String.fromInt (String.length model.sourceText))
            , E.paragraph [E.width (E.px 350)] [E.text <| "Editor event: " ++ Debug.toString model.editorEvent]
            , E.paragraph [E.width (E.px 350)] [ E.text <| "Edit command: " ++ Debug.toString model.editCommand]
            , E.paragraph [E.width (E.px 350)] [ E.text <| "OT Document: " ++ Debug.toString model.oTDocument]
            , E.paragraph [E.width (E.px 350)] [ E.text <| "OT Document (2): " ++ Debug.toString model.networkModel.serverState.document]
            , E.paragraph [E.width (E.px 350)] [ E.text <| "Local Msgs: " ++ Debug.toString model.networkModel.localMsgs]
            , E.paragraph [E.width (E.px 350)] [ E.text <| "Cursor Pos: "
                  ++ Debug.toString (model.networkModel.serverState.cursorPositions |> NetworkModel.shortenDictKeys)]
            ]
        _ -> E.none


