module View.Style exposing
    ( bgGray
    , buttonStyle
    , buttonStyle2
    , buttonStyle3
    , buttonStyleSmall
    , fgGray
    , mainColumn
    )

import Element
import Element.Background as Background
import Element.Font as Font
import View.Geometry as Geometry


mainColumn model =
    [ bgGray 0.5
    , Element.paddingEach { top = 20, bottom = 0, left = 0, right = 0 }

    ---, Element.width (Element.px model.windowWidth)
    , Element.width (Element.px <| Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth)
    , Element.height (Element.px model.windowHeight)
    ]


fgGray : Float -> Element.Attr decorative msg
fgGray g =
    Font.color (Element.rgb g g g)


bgGray : Float -> Element.Attr decorative msg
bgGray g =
    Background.color (Element.rgb g g g)


buttonStyleSmall : List (Element.Attr () msg)
buttonStyleSmall =
    [ Font.color (Element.rgb255 255 255 255)
    , Element.paddingXY 4 4
    ]


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
