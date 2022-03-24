module View.Sidebar exposing (view)

import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Dict exposing (Dict)
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Render.Markup
import Render.Settings
import Render.TOC
import String.Extra
import Time
import Types exposing (ActiveDocList(..), AppMode(..), DocPermissions(..), FrontendModel, FrontendMsg(..), MaximizedIndex(..), SidebarState(..), SortMode(..))
import View.Button as Button
import View.Color as Color
import View.Editor as Editor
import View.Geometry as Geometry
import View.Input
import View.Style
import View.Utility


view : FrontendModel -> Element FrontendMsg
view model =
    case model.sidebarState of
        SidebarIn ->
            E.none

        SidebarOut ->
            E.column [ E.scrollbarY, E.width (E.px Geometry.sidebarWidth), E.spacing 4, E.height (E.px (Geometry.appHeight_ model - 110)), E.paddingXY 8 0, Background.color Color.lightGray ]
                (Button.getUserTags model.currentUser :: viewTagDict model.tagDict)


viewTagDict : Dict String (List { a | id : String, title : String }) -> List (Element FrontendMsg)
viewTagDict dict =
    dict
        |> Dict.toList
        |> List.map (\( tag, list ) -> List.map (\item -> { tag = tag, id = item.id, title = item.title }) list)
        |> List.map viewTagGroup


viewTagGroup : List { tag : String, id : String, title : String } -> Element FrontendMsg
viewTagGroup list =
    case List.head list of
        Nothing ->
            E.none

        Just headItem ->
            E.column [ E.spacing 2, E.paddingEach { top = 8, bottom = 0, left = 0, right = 0 } ] (E.el [ E.paddingXY 6 0, Font.size 14 ] (E.text headItem.tag) :: List.map viewTagDictItem list)



-- E.paddingEach {top = 8, bottom = 0, left = 0, right = 0}


viewTagDictItem : { tag : String, id : String, title : String } -> Element FrontendMsg
viewTagDictItem data =
    E.row [ Font.size 14, E.spacing 8 ] [ E.el [] (Button.getDocument data.id (View.Utility.softTruncate 30 data.title)) ]
