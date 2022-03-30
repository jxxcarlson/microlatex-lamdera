module View.Main exposing (view)

import Element as E exposing (Element)
import Html exposing (Html)
import Types exposing (AppMode(..), FrontendModel, FrontendMsg)
import View.Admin as Admin
import View.Editor as Editor
import View.Footer as Footer
import View.Geometry as Geometry
import View.Header as Header
import View.Index as Index
import View.Rendered as Rendered
import View.Sidebar as Sidebar
import View.SignUp as SignUp
import View.Style as Style
import View.Utility


type alias Model =
    FrontendModel


view : Model -> Html FrontendMsg
view model =
    E.layoutWith { options = [ E.focusStyle View.Utility.noFocus ] }
        [ Style.bgGray 0.9, E.clipX, E.clipY ]
        (viewMainColumn model)


viewMainColumn : Model -> Element FrontendMsg
viewMainColumn model =
    case model.appMode of
        AdminMode ->
            Admin.view model

        UserMode ->
            if model.showEditor then
                viewEditorAndRenderedText model

            else
                viewRenderedTextOnly model


viewEditorAndRenderedText : Model -> Element FrontendMsg
viewEditorAndRenderedText model =
    let
        deltaH =
            (Geometry.appHeight_ model - 100) // 2 + 130
    in
    E.column (Style.mainColumn model)
        [ E.column [ E.spacing 12, E.centerX, E.width (E.px <| Geometry.appWidth model.sidebarState model.windowWidth), E.height (E.px (Geometry.appHeight_ model)) ]
            [ Header.view model (E.px <| Geometry.appWidth model.sidebarState model.windowWidth)
            , E.row [ E.spacing 12 ]
                [ Editor.view model
                , Rendered.viewForEditor model (Geometry.panelWidth_ model.sidebarState model.windowWidth)
                , Index.view model (Geometry.appWidth model.sidebarState model.windowWidth) deltaH
                , Sidebar.view model
                ]
            , Footer.view model (Geometry.appWidth model.sidebarState model.windowWidth)
            ]
        ]


viewRenderedTextOnly : Model -> Element FrontendMsg
viewRenderedTextOnly model =
    let
        deltaH =
            (Geometry.appHeight_ model - 100) // 2 + 130
    in
    E.column (Style.mainColumn model)
        [ E.column [ E.centerX, E.spacing 12, E.width (E.px <| Geometry.smallAppWidth model.windowWidth), E.height (E.px (Geometry.appHeight_ model)) ]
            [ Header.view model (E.px <| Geometry.smallHeaderWidth model.windowWidth)
            , E.row [ E.spacing 12, E.inFront (SignUp.view model) ]
                [ viewRenderedContainer model
                , Index.view model (Geometry.smallAppWidth model.windowWidth) deltaH
                , Sidebar.view model
                ]
            , Footer.view model (Geometry.smallHeaderWidth model.windowWidth)
            ]
        ]



-- HELPERS


viewRenderedContainer model =
    E.column [ E.spacing 18 ]
        [ Rendered.view model (Geometry.smallPanelWidth model.windowWidth)
        ]
