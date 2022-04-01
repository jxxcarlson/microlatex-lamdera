module View.Admin exposing (view)

import Element as E exposing (Element)
import Types exposing (FrontendModel, FrontendMsg)
import View.Button as Button
import View.Footer as Footer
import View.Geometry as Geometry
import View.Header as Header
import View.Input
import View.Style as Style
import View.Utility


view : FrontendModel -> Element FrontendMsg
view model =
    E.column (Style.mainColumn model)
        [ E.column [ E.spacing 12, E.centerX, E.width (E.px <| Geometry.appWidth model.sidebarState model.windowWidth), E.height (E.px (Geometry.appHeight_ model)) ]
            [ Header.view model (E.px <| Geometry.appWidth model.sidebarState model.windowWidth)
            , E.row [ E.spacing 12 ]
                [ View.Utility.showIf (View.Utility.isAdmin model) (View.Input.specialInput model)
                , Button.runSpecial
                , Button.toggleAppMode model
                ]
            , Footer.view model (Geometry.appWidth model.sidebarState model.windowWidth)
            ]
        ]
