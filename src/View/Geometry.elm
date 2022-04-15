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

import Types exposing (SidebarExtrasState(..))


appHeight_ model =
    model.windowHeight - 60


panelHeight_ model =
    appHeight_ model - 110



-- DIMENSIONS


innerGutter =
    12


outerGutter =
    12


panelWidth_ : SidebarExtrasState -> Int -> Int
panelWidth_ sidebarState ww =
    (appWidth SidebarExtrasIn ww - indexWidth ww) // 2 - innerGutter - outerGutter


panelWidth2_ : SidebarExtrasState -> Int -> Int
panelWidth2_ sidebarState ww =
    appWidth SidebarExtrasIn ww - indexWidth ww - innerGutter



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
        SidebarExtrasOut ->
            ramp 700 (1400 + sidebarWidth) ww

        SidebarExtrasIn ->
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
