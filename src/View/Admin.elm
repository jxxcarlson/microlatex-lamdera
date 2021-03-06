module View.Admin exposing (view)

import Document
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import String.Extra
import Types exposing (FrontendModel, FrontendMsg)
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
            , E.width (E.px <| Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth)
            , E.height (E.px (Geometry.appHeight model))
            ]
            [ adminHeader model
            , adminBody model
            , adminFooter model
            ]
        ]


adminHeader model =
    E.row [ E.spacing 12 ]
        [ Button.getUserList
        , Button.clearConnectionDict
        , Button.toggleAppMode model
        ]


adminBody : FrontendModel -> Element FrontendMsg
adminBody model =
    E.column
        [ E.spacing 12
        , E.centerX
        , E.width (E.px <| Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth)
        , E.height (E.px (Geometry.appHeight model - 150))
        , Background.color View.Color.white
        , Font.size 14
        , E.padding 20
        , E.scrollbarY
        ]
        [ E.row [ E.spacing 36 ]
            [ viewUserList model.userList
            , viewConnectedUsers model.connectedUsers
            , viewSharedDocuments model.sharedDocumentList
            ]
        ]


viewConnectedUsers : List String -> Element FrontendMsg
viewConnectedUsers users =
    E.column [ E.alignTop, E.spacing 8 ] (E.el [ Font.bold ] (E.text "Connected Users") :: List.map (\u -> viewConnectedUser u) users)


viewConnectedUser : String -> Element FrontendMsg
viewConnectedUser data =
    E.el [ Font.size 14 ] (E.text (String.Extra.softEllipsis 80 data))


viewSharedDocuments : List ( String, Bool, Types.SharedDocument ) -> Element FrontendMsg
viewSharedDocuments sharedDocuments =
    E.column [ E.alignTop, E.spacing 12 ] (E.el [ Font.bold ] (E.text "Shared documents") :: List.map viewSharedDocument sharedDocuments)


viewSharedDocument : ( String, Bool, Types.SharedDocument ) -> Element FrontendMsg
viewSharedDocument ( author, online, data ) =
    E.row [ E.spacing 12 ]
        (List.map E.text
            [ author ++ isOnline online
            , data.title
            , data.share |> Document.shareToString
            , data.currentEditors |> List.map .username |> String.join ", "
            ]
        )


isOnline : Bool -> String
isOnline isOnline_ =
    if isOnline_ then
        " (online)"

    else
        ""


adminFooter model =
    E.row [ E.spacing 12 ]
        [ View.Input.specialInput model
        , Button.runSpecial
        ]


viewUserList : List ( String, Int ) -> Element FrontendMsg
viewUserList users =
    E.column [ E.alignTop, E.spacing 8 ]
        (E.el [ Font.bold ] (E.text "Users") :: List.map viewUser (List.sortBy (\( u, _ ) -> u) users))


viewUser : ( String, Int ) -> Element FrontendMsg
viewUser ( username, numberOnLine ) =
    if numberOnLine == 0 then
        E.row [ E.spacing 8, E.width (E.px 150) ] [ E.el [ E.width (E.px 50) ] (E.text <| username) ]

    else
        E.row [ E.spacing 8, E.width (E.px 150) ] [ E.el [ E.width (E.px 50) ] (E.text <| username ++ ": " ++ String.fromInt numberOnLine) ]
