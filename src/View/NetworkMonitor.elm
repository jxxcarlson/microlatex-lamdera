module View.NetworkMonitor exposing (view)

import CollaborativeEditing.NetworkModel as NetworkModel
import Dict
import Element as E
import Element.Background as Background
import Element.Font as Font
import Types exposing (..)
import View.Button
import View.Color as Color
import View.Input


view model =
    case model.popupState of
        NetworkMonitorPopup ->
            let
                dx =
                    if model.showEditor then
                        950

                    else
                        700
            in
            E.column
                [ E.width (E.px 400)
                , E.height (E.px 560)
                , Background.color Color.paleBlue
                , Font.size 14
                , E.moveUp 580
                , E.moveRight dx
                , E.spacing 12
                , E.paddingXY 20 20
                ]
                [ E.row [ E.width (E.px 360) ] [ E.text "NetworkMonitor", E.el [ E.alignRight ] View.Button.dismissPopup ]
                , E.row [ E.spacing 12 ] [ View.Input.editorCommand 200 model, View.Button.runNetworkModelCommand ]
                , E.text <| "Source length: " ++ String.fromInt (String.length model.sourceText)
                , E.paragraph [ E.width (E.px 350) ] [ E.text <| "Editor event: " ++ Debug.toString model.editorEvent ]
                , E.paragraph [ E.width (E.px 350) ] [ E.text <| "Edit command: " ++ Debug.toString model.editCommand ]
                , E.paragraph [ E.width (E.px 350) ] [ E.text <| "Cursor: " ++ String.fromInt model.networkModel.serverState.document.cursor ]
                , E.paragraph [ E.width (E.px 350) ] [ E.text <| "Content: " ++ model.networkModel.serverState.document.content ]
                , E.paragraph [ E.width (E.px 350) ] [ E.text <| "Cursors: " ++ cursorsToString model.networkModel.serverState.cursorPositions ]
                , View.Button.applyEdits
                , E.column [ E.height (E.px 300), E.scrollbarY, E.spacing 6 ]
                    (List.map (NetworkModel.toStringRecord >> viewData) model.networkModel.localMsgs)
                ]

        _ ->
            E.none


cursorsToString : Dict.Dict String Int -> String
cursorsToString dict =
    dict
        |> Dict.toList
        |> List.map
            (\( id, cursor ) ->
                "(" ++ String.left 2 id ++ ", " ++ String.fromInt cursor ++ ")"
            )
        |> String.join "; "


viewData : { ids : String, dp : String, op : String } -> E.Element msg
viewData { ids, dp, op } =
    E.row [ E.spacing 4 ]
        [ E.el [ E.width (E.px 50) ] (E.text ids)
        , E.el [ E.width (E.px 20), E.alignRight ] (E.text dp)
        , E.el [ E.width (E.px 120) ] (E.text op)
        ]
