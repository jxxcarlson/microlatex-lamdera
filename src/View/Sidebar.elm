module View.Sidebar exposing (view)

import Dict exposing (Dict)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Types exposing (FrontendModel, FrontendMsg, SidebarState(..))
import View.Button as Button
import View.Color as Color
import View.Geometry as Geometry
import View.Input
import View.Utility


view : FrontendModel -> Element FrontendMsg
view model =
    case model.sidebarState of
        SidebarIn ->
            E.none

        SidebarOut ->
            E.column
                [ E.width (E.px Geometry.sidebarWidth)
                , E.spacing 4
                , E.height (E.px (Geometry.appHeight_ model - 110))
                , E.paddingXY 8 0
                , Background.color Color.lightGray
                ]
                [ E.row [ E.spacing 12 ] [ Button.getUserTags model.tagSelection model.currentUser, Button.getPublicTags model.tagSelection ]
                , search model
                , E.column
                    [ E.scrollbarY
                    , E.width (E.px Geometry.sidebarWidth)
                    , E.spacing 4
                    , E.height (E.px (Geometry.appHeight_ model - 190))
                    ]
                    (viewTagDict model.inputSearchTagsKey model.tagDict)
                ]


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


viewTagDict : String -> Dict String (List { a | id : String, title : String }) -> List (Element FrontendMsg)
viewTagDict key dict =
    dict
        |> Dict.toList
        |> List.map (\( tag, list ) -> List.map (\item -> { tag = tag, id = item.id, title = item.title }) list)
        |> List.map (searchTags key)
        |> List.map viewTagGroup


viewTagGroup : List { tag : String, id : String, title : String } -> Element FrontendMsg
viewTagGroup list =
    case List.head list of
        Nothing ->
            E.none

        Just headItem ->
            E.column [ E.spacing 2, E.paddingEach { top = 8, bottom = 0, left = 0, right = 0 } ] (E.el [ E.paddingXY 6 0, Font.size 14 ] (E.text headItem.tag) :: List.map viewTagDictItem list)


viewTagDictItem : { tag : String, id : String, title : String } -> Element FrontendMsg
viewTagDictItem data =
    E.row [ Font.size 14, E.spacing 8 ] [ E.el [] (Button.getDocument data.id (View.Utility.softTruncate 30 data.title)) ]
