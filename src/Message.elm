module Message exposing (handleMessage, make)

import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Types
import View.Color


style attr =
    [ Font.size 14 ] ++ attr


make : String -> Types.MessageStatus -> List Types.Message
make str status =
    [ { txt = str, status = status } ]


handleMessage : Types.Message -> Element msg
handleMessage { txt, status } =
    case status of
        Types.MSWhite ->
            E.el (style []) (E.text txt)

        Types.MSYellow ->
            E.el (style [ Font.color View.Color.yellow ]) (E.text txt)

        Types.MSGreen ->
            E.el (style [ Font.color (E.rgb 0 0.7 0) ]) (E.text txt)

        Types.MSRed ->
            E.el (style [ Font.color View.Color.white, Background.color View.Color.red, E.paddingXY 4 4 ]) (E.text txt)
