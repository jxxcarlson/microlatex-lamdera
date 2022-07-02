module View.Popups.NewFolder exposing (view)

import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Types
import View.Button
import View.Input


view : Types.FrontendModel -> Element Types.FrontendMsg
view model =
    case model.popupState of
        Types.FolderPopup ->
            Element.column
                [ Background.color (Element.rgb 0.4 0.4 0.7)
                , Font.size 12
                , Element.height (Element.px 200)
                , Element.spacing 12
                , Element.paddingXY 12 12
                , Element.moveDown (toFloat <| 50)
                , Element.alignRight
                , Element.width (Element.px 265)
                ]
                [ Element.el [ Element.paddingXY 0 8, Font.size 18, Font.color (Element.rgb 1 1 1) ] (Element.text "New Folder")
                , View.Input.folderName model
                , View.Input.folderTag model
                , View.Button.createFolder
                ]

        _ ->
            Element.none
