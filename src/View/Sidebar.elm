module View.Sidebar exposing (viewExtras, viewTags)

import Dict exposing (Dict)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import String.Extra
import Types exposing (FrontendModel, FrontendMsg, SidebarExtrasState(..), SidebarTagsState(..))
import User
import View.Button as Button
import View.Color as Color
import View.Geometry as Geometry
import View.Input
import View.Utility


viewExtras : FrontendModel -> Element FrontendMsg
viewExtras model =
    case model.sidebarExtrasState of
        SidebarExtrasIn ->
            E.none

        SidebarExtrasOut ->
            E.column
                [ E.width (E.px Geometry.sidebarWidth)
                , E.spacing 4
                , E.height (E.px (Geometry.appHeight_ model - 110))
                , E.paddingXY 12 12
                , Font.size 14
                , Background.color Color.lightGray
                ]
                [ viewUserList model.userList
                ]


viewUserList : List ( String, Bool ) -> Element FrontendMsg
viewUserList users =
    E.column [ E.spacing 8 ]
        (E.el [ Font.bold ] (E.text "Users") :: List.map viewUser (List.sortBy (\( u, _ ) -> u) users))


viewUser : ( String, Bool ) -> Element FrontendMsg
viewUser ( username, isOnline_ ) =
    E.row [ E.spacing 8, E.width (E.px 150) ] [ E.el [ E.width (E.px 50) ] (E.text <| username ++ isOnline isOnline_) ]


isOnline : Bool -> String
isOnline isOnline_ =
    if isOnline_ then
        " (online)"

    else
        ""


viewTags : FrontendModel -> Element FrontendMsg
viewTags model =
    case model.sidebarTagsState of
        SidebarTagsIn ->
            E.none

        SidebarTagsOut ->
            E.column
                [ E.width (E.px Geometry.sidebarWidth)
                , E.spacing 4
                , E.height (E.px (Geometry.appHeight_ model - 110))
                , E.paddingXY 8 0
                , Background.color Color.lightGray
                ]
                [ E.row [ E.spacing 12, E.paddingEach { top = 12, bottom = 0, left = 0, right = 0 } ]
                    [ Button.getUserTags model.tagSelection model.currentUser, Button.getPublicTags model.tagSelection ]
                , search model
                , viewTagDict model
                ]


viewTagDict model =
    let
        dictItems =
            case model.tagSelection of
                Types.TagPublic ->
                    Dict.toList model.publicTagDict

                Types.TagUser ->
                    Dict.toList model.tagDict

        header =
            E.el [ Font.size 14, E.paddingXY 2 4 ] (E.text <| "Tags: " ++ (List.length dictItems |> String.fromInt))
    in
    E.column
        [ E.scrollbarY
        , E.width (E.px Geometry.sidebarWidth)
        , E.spacing 4
        , E.height (E.px (Geometry.appHeight_ model - 190))
        ]
        (header :: viewTagDict_ model.inputSearchTagsKey dictItems)


search model =
    if Dict.isEmpty model.tagDict then
        E.none

    else
        View.Input.searchTagsInput model


searchTags : String -> List { tag : String, id : String, title : String } -> List { tag : String, id : String, title : String }
searchTags key_ list =
    let
        key =
            String.toLower key_
    in
    if key == "" then
        list

    else
        List.filter (\item -> String.contains key item.tag || String.contains key (String.toLower item.title)) list


viewTagDict_ : String -> List ( String, List { a | id : String, title : String } ) -> List (Element FrontendMsg)
viewTagDict_ key dictItems =
    dictItems
        |> List.map (\( tag, list ) -> List.map (\item -> { tag = tag, id = item.id, title = item.title }) list)
        |> List.map (searchTags key)
        |> List.map viewTagGroup


viewTagGroup : List { tag : String, id : String, title : String } -> Element FrontendMsg
viewTagGroup list =
    let
        n =
            " (" ++ (List.length list |> String.fromInt) ++ ")"
    in
    case List.head list of
        Nothing ->
            E.none

        Just headItem ->
            E.column [ E.spacing 2, E.paddingEach { top = 8, bottom = 0, left = 0, right = 0 } ]
                (E.el [ E.paddingXY 6 0, Font.size 14 ] (E.text (headItem.tag ++ n)) :: List.map viewTagDictItem (List.sortBy .title list))


viewTagDictItem : { tag : String, id : String, title : String } -> Element FrontendMsg
viewTagDictItem data =
    E.row [ Font.size 14, E.spacing 8 ] [ E.el [] (Button.getDocument Types.StandardHandling data.id (String.Extra.ellipsisWith 30 " ..." data.title) False) ]
