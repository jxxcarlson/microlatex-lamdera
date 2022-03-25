module View.Style exposing
    ( bgBlack
    , bgGray
    , bgWhite
    , buttonStyle
    , buttonStyle2
    , buttonStyle3
    , fgBlack
    , fgGray
    , fgWhite
    , mainColumn
    )

import Element
import Element.Background as Background
import Element.Font as Font


mainColumn model =
    [ bgGray 0.5
    , Element.paddingEach { top = 40, bottom = 20, left = 0, right = 0 }
    , Element.width (Element.px model.windowWidth)
    , Element.height (Element.px model.windowHeight)
    ]


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


buttonStyle3 : List (Element.Attr () msg)
buttonStyle3 =
    [ Font.color (Element.rgb255 20 20 20)
    , Element.paddingXY 5 0
    ]
