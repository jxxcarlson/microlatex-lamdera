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
    [ { content = str, status = status } ]


handleMessage : Types.Message -> Element msg
handleMessage { content, status } =
    case status of
        Types.MSNormal ->
            E.el (style []) (E.text content)

        Types.MSWarning ->
            E.el (style [ Font.color View.Color.yellow ]) (E.text content)

        Types.MSGreen ->
            E.el (style [ Font.color (E.rgb 0 0.7 0) ]) (E.text content)

        Types.MSError ->
            E.el (style [ Font.color View.Color.white, Background.color View.Color.red, E.paddingXY 4 4 ]) (E.text content)
