module View.Color exposing
    ( black
    , blue
    , darkBlue
    , darkGray
    , darkRed
    , gray
    , lightBlue
    , lightGray
    , medGray
    , mediumPaleBlue
    , paleBlue
    , paleGreen
    , palePink
    , paleViolet
    , red
    , transparentBlue
    , veryPaleBlue
    , violet
    , white
    , yellow
    )

import Element as E


paleGreen =
    E.rgb 0.85 0.95 0.98


white : E.Color
white =
    E.rgb 255 255 255


palePink =
    E.rgb 1.0 0.9 0.93


lightGray : E.Color
lightGray =
    gray 0.9


medGray : E.Color
medGray =
    gray 0.5


darkGray : E.Color
darkGray =
    gray 0.3


black : E.Color
black =
    gray 0.2


red : E.Color
red =
    E.rgb255 255 0 0


darkRed : E.Color
darkRed =
    E.rgb255 140 0 0


blue : E.Color
blue =
    E.rgb255 0 0 140


darkBlue : E.Color
darkBlue =
    E.rgb255 0 0 120


lightBlue : E.Color
lightBlue =
    E.rgb255 120 120 200


yellow =
    E.rgb 0.8 0.8 0


paleBlue : E.Color
paleBlue =
    E.rgb255 180 180 255


veryPaleBlue : E.Color
veryPaleBlue =
    E.rgb 0.9 0.9 1.0


mediumPaleBlue : E.Color
mediumPaleBlue =
    E.rgb 0.85 0.85 1.0


transparentBlue : E.Color
transparentBlue =
    E.rgba 0.9 0.9 1 0.9


paleViolet : E.Color
paleViolet =
    E.rgb255 230 230 255


violet : E.Color
violet =
    E.rgb 0.95 0.9 1.0


gray : Float -> E.Color
gray g =
    E.rgb g g g
