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

import Types exposing (SidebarExtrasState(..), SidebarTagsState(..))


appWidth : SidebarExtrasState -> SidebarTagsState -> Int -> Int
appWidth sidebarExtrasState sidebarTags ww =
    case ( sidebarExtrasState, sidebarTags ) of
        ( SidebarExtrasOut, _ ) ->
            ramp 700 1400 ww

        ( _, SidebarTagsOut ) ->
            ramp 700 1400 ww

        ( SidebarExtrasIn, SidebarTagsIn ) ->
            ramp 700 1400 ww


appHeight_ model =
    model.windowHeight - 60


panelHeight_ model =
    appHeight_ model - 110


panelWidth_ : SidebarExtrasState -> SidebarTagsState -> Int -> Int
panelWidth_ sidebarState sidebarTagsState ww =
    (appWidth sidebarState sidebarTagsState ww - indexWidth ww) // 2 - innerGutter - outerGutter


panelWidth2_ : SidebarExtrasState -> SidebarTagsState -> Int -> Int
panelWidth2_ sidebarState sidebarTagsState ww =
    appWidth sidebarState sidebarTagsState ww - indexWidth ww - innerGutter



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


smallAppWidth ww =
    ramp 700 900 ww


ramp a b x =
    if x < a then
        a

    else if x > b then
        b

    else
        x



-- DIMENSIONS


innerGutter =
    12


outerGutter =
    12
