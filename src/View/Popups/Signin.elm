module View.Popups.Signin exposing (view)

import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Types
import View.Geometry as Geometry


view : Types.FrontendModel -> Element msg
view model =
    if model.showSignInTimer then
        Element.column
            [ Background.color (Element.rgb 0.6 0.6 1.0)
            , Font.color (Element.rgb 1 1 1)
            , Font.size 12
            , Element.height (Element.px 72)
            , Element.spacing 12
            , Element.paddingXY 12 8
            , Element.moveDown (toFloat <| 45)
            , Element.alignRight
            , Element.width (Element.px 250)
            ]
            [ Element.text <| "Starting ... " ++ String.fromInt model.timer ++ " seconds"
            , Element.text (model.messages |> List.head |> Maybe.map .txt |> Maybe.withDefault "")
            ]

    else
        Element.none
