module View.Popups.Signin exposing (view)

import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Types


view : Types.FrontendModel -> Element msg
view model =
    if model.showSignInTimer then
        Element.column
            [ Background.color (Element.rgb 0 0 0.8)
            , Font.color (Element.rgb 1 1 1)
            , Font.size 12
            , Element.height (Element.px 72)
            , Element.spacing 12
            , Element.paddingXY 12 12
            , Element.moveDown (toFloat <| 50)
            , Element.alignRight
            , Element.width (Element.px 265)
            ]
            [ if model.timer < 10 then
                Element.text <| "Signing in ... " ++ String.fromInt model.timer ++ " seconds"

              else
                Element.text <| "ost connection ... reload browser"
            , Element.text (model.messages |> List.head |> Maybe.map .txt |> Maybe.withDefault "" |> filter)
            ]

    else
        Element.none


filter : String -> String
filter str =
    if String.contains "(std)" str then
        ""

    else
        str
