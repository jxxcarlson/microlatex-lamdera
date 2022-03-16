module View.Style exposing
    ( bgBlack
    , bgGray
    , bgWhite
    , buttonStyle
    , buttonStyle2
    , fgBlack
    , fgGray
    , fgWhite
    )

import Element
import Element.Background as Background
import Element.Font as Font


fgBlack =
    fgGray 0


fgWhite =
    fgGray 1


bgBlack =
    bgGray 0


bgWhite =
    bgGray 1


fgGray : Float -> Element.Attr decorative msg
fgGray g =
    Font.color (Element.rgb g g g)


bgGray : Float -> Element.Attr decorative msg
bgGray g =
    Background.color (Element.rgb g g g)


buttonStyle : List (Element.Attr () msg)
buttonStyle =
    [ Font.color (Element.rgb255 255 255 255)
    , Element.paddingXY 15 8
    ]


buttonStyle2 : List (Element.Attr () msg)
buttonStyle2 =
    [ Font.color (Element.rgb255 20 20 20)
    , Element.paddingXY 0 8
    ]
