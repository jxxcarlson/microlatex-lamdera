module View.Admin exposing (view)

import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Types exposing (FrontendModel, FrontendMsg)
import User
import View.Button as Button
import View.Color
import View.Footer as Footer
import View.Geometry as Geometry
import View.Header as Header
import View.Input
import View.Style as Style
import View.Utility


view : FrontendModel -> Element FrontendMsg
view model =
    E.column (Style.mainColumn model)
        [ E.column
            [ E.spacing 12
            , E.centerX
            , E.width (E.px <| Geometry.appWidth model.sidebarState model.windowWidth)
            , E.height (E.px (Geometry.appHeight_ model))
            ]
            [ Header.view model (E.px <| Geometry.appWidth model.sidebarState model.windowWidth)
            , E.column
                [ E.spacing 12
                , E.centerX
                , E.width (E.px <| Geometry.appWidth model.sidebarState model.windowWidth)
                , E.height (E.px (Geometry.appHeight_ model - 150))
                , Background.color View.Color.white
                , Font.size 14
                , E.padding 20
                , E.scrollbarY
                ]
                (viewUserList model.userList)
            , E.row [ E.spacing 12 ]
                [ View.Utility.showIf (View.Utility.isAdmin model) (View.Input.specialInput model)
                , Button.runSpecial
                , Button.getUserList
                ]
            , Footer.view model (Geometry.appWidth model.sidebarState model.windowWidth)
            ]
        ]


viewUserList : List ( User.User, Int ) -> List (Element FrontendMsg)
viewUserList users =
    List.map viewUser (List.sortBy (\( u, k ) -> u.username) users)


viewUser : ( User.User, Int ) -> Element FrontendMsg
viewUser ( user, k ) =
    E.row [ E.spacing 8, E.width (E.px 300) ] [ E.el [ E.width (E.px 150) ] (E.text user.username), E.el [ E.width (E.px 80), E.alignRight ] (E.text (String.fromInt k)) ]
