module View.Geometry exposing
    ( appHeight_
    , appWidth
    , indexWidth
    , panelHeight_
    , panelWidth2_
    , panelWidth_
    , sidebarWidth
    , smallAppWidth
    , smallHeaderWidth
    , smallPanelWidth
    )

import Types exposing (SidebarState(..))


appHeight_ model =
    model.windowHeight - 30


panelHeight_ model =
    appHeight_ model - 110



-- DIMENSIONS


innerGutter =
    12


outerGutter =
    12


panelWidth_ : SidebarState -> Int -> Int
panelWidth_ sidebarState ww =
    (appWidth SidebarIn ww - indexWidth ww) // 2 - innerGutter - outerGutter


panelWidth2_ : SidebarState -> Int -> Int
panelWidth2_ sidebarState ww =
    appWidth SidebarIn ww - indexWidth ww - innerGutter



-- BOTTOM


smallPanelWidth ww =
    smallAppWidth ww - indexWidth ww - innerGutter


smallHeaderWidth ww =
    smallAppWidth ww


indexWidth : number -> number
indexWidth ww =
    ramp 150 300 ww


sidebarWidth =
    250


appWidth sidebarState ww =
    case sidebarState of
        SidebarOut ->
            ramp 700 (1400 + sidebarWidth) ww

        SidebarIn ->
            ramp 700 1400 ww


smallAppWidth ww =
    ramp 700 900 ww


ramp a b x =
    if x < a then
        a

    else if x > b then
        b

    else
        x
