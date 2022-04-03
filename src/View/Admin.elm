module View.Admin exposing (view)

import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Types exposing (FrontendModel, FrontendMsg)
import User
import View.Button as Button
import View.Color
import View.Geometry as Geometry
import View.Input
import View.Style as Style


view : FrontendModel -> Element FrontendMsg
view model =
    E.column (Style.mainColumn model)
        [ E.column
            [ E.spacing 12
            , E.centerX
            , E.width (E.px <| Geometry.appWidth model.sidebarState model.windowWidth)
            , E.height (E.px (Geometry.appHeight_ model))
            ]
            [ adminHeader model
            , adminBody model
            , adminFooter model
            ]
        ]


adminHeader model =
    E.row [ E.spacing 12 ]
        [ Button.getUserList
        ]


adminBody model =
    E.column
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


adminFooter model =
    E.row [ E.spacing 12 ]
        [ View.Input.specialInput model
        , Button.runSpecial
        , Button.toggleAppMode model
        ]


viewUserList : List ( User.User, Int ) -> List (Element FrontendMsg)
viewUserList users =
    List.map viewUser (List.sortBy (\( u, _ ) -> u.username) users)


viewUser : ( User.User, Int ) -> Element FrontendMsg
viewUser ( user, k ) =
    E.row [ E.spacing 8, E.width (E.px 100) ] [ E.el [ E.width (E.px 50) ] (E.text user.username), E.el [ E.width (E.px 20), E.alignRight ] (E.text (String.fromInt k)) ]
