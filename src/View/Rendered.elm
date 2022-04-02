module View.Rendered exposing (view, viewForEditor, viewSmall)

import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Html.Attributes as HtmlAttr
import Render.Markup
import Render.Settings
import Render.TOC
import Types exposing (FrontendModel, FrontendMsg(..))
import View.Button as Button
import View.Geometry as Geometry
import View.Style as Style
import View.Utility


view : FrontendModel -> Int -> Element FrontendMsg
view model width_ =
    case model.currentDocument of
        Nothing ->
            E.none

        Just _ ->
            E.column
                [ E.paddingEach { left = 24, right = 24, top = 32, bottom = 96 }
                , Style.bgGray 1.0
                , E.width (E.px width_)
                , E.height (E.px (Geometry.panelHeight_ model))
                , Font.size 14
                , E.alignTop
                , E.scrollbarY
                , View.Utility.elementAttribute "id" "__RENDERED_TEXT__"
                ]
                [ View.Utility.katexCSS
                , E.column [ E.spacing 18, E.width (E.px (width_ - 60)) ]
                    (viewDocument (affine 1.75 -650 (Geometry.panelWidth2_ model.sidebarState model.windowWidth)) model.counter model.selectedId model.editRecord)
                ]


viewSmall : FrontendModel -> Document -> Int -> Int -> Int -> Element FrontendMsg
viewSmall model doc width_ deltaH indexShift =
    let
        editRecord =
            Compiler.DifferentialParser.init doc.language doc.content

        currentDocId =
            Maybe.map .id model.currentDocument |> Maybe.withDefault "???"
    in
    E.column
        [ E.paddingEach { left = 12, right = 12, top = 18, bottom = 96 }
        , Background.color (E.rgb 1.0 1.0 0.9)
        , Style.bgGray 1.0
        , E.width (E.px <| Geometry.indexWidth model.windowWidth)
        , E.height (E.px (Geometry.appHeight_ model - deltaH + indexShift))
        , Font.size 14
        , E.alignTop
        , E.scrollbarY
        , View.Utility.elementAttribute "id" "__RENDERED_TEXT__"
        ]
        [ View.Utility.katexCSS
        , E.column [ E.spacing 4, E.width (E.px (Geometry.indexWidth model.windowWidth - 20)) ]
            (viewDocumentSmall (affine 1.75 -650 (Geometry.indexWidth model.windowWidth)) model.counter currentDocId editRecord)

        -- (viewDocumentSmall (Geometry.indexWidth model.windowWidth) model.counter currentDocId editRecord)
        ]


viewForEditor : FrontendModel -> Int -> Element FrontendMsg
viewForEditor model width_ =
    case model.currentDocument of
        Nothing ->
            E.none

        Just _ ->
            E.column
                [ E.paddingEach { left = 24, right = 24, top = 32, bottom = 96 }
                , Style.bgGray 1.0
                , E.width (E.px width_)
                , E.height (E.px (Geometry.panelHeight_ model))
                , Font.size 14
                , E.alignTop
                , E.scrollbarY
                , View.Utility.elementAttribute "id" "__RENDERED_TEXT__"
                ]
                [ View.Utility.katexCSS
                , E.column [ E.spacing 18, E.width (E.px (width_ - 60)) ]
                    (viewDocument (affine 1.8 0 (Geometry.panelWidth_ model.sidebarState model.windowWidth)) model.counter model.selectedId model.editRecord)
                ]



-- HELPERS


viewDocumentSmall windowWidth counter currentDocId editRecord =
    let
        title_ : Element FrontendMsg
        title_ =
            Compiler.ASTTools.title editRecord.parsed
                |> (\s ->
                        E.paragraph
                            [ E.htmlAttribute (HtmlAttr.id "title")
                            , Font.size 16
                            , E.paddingEach { top = 0, bottom = 12, left = 0, right = 0 }
                            ]
                            [ E.text s ]
                   )

        body : List (Element FrontendMsg)
        body =
            Render.Markup.renderFromAST counter editRecord.accumulator (renderSettings currentDocId windowWidth) editRecord.parsed |> List.map (E.map Render)
    in
    E.row [ Background.color (E.rgb 0.8 0.8 1.0), E.paddingEach { left = 8, right = 8, top = 12, bottom = 0 }, E.spacing 16, E.width E.fill ] [ title_, E.el [ E.moveUp 6, E.alignRight, E.paddingEach { left = 0, right = 8, top = 0, bottom = 0 } ] Button.closeCollectionsIndex ] :: body


viewDocument windowWidth counter selectedId editRecord =
    let
        title_ : Element FrontendMsg
        title_ =
            Compiler.ASTTools.title editRecord.parsed
                |> (\s -> E.paragraph [ E.htmlAttribute (HtmlAttr.id "title"), Font.size Config.titleSize ] [ E.text s ])

        toc : Element FrontendMsg
        toc =
            Render.TOC.view counter editRecord.accumulator (renderSettings selectedId windowWidth |> setSelectedId selectedId) editRecord.parsed |> E.map Render

        body : List (Element FrontendMsg)
        body =
            Render.Markup.renderFromAST counter editRecord.accumulator (renderSettings selectedId windowWidth) editRecord.parsed |> List.map (E.map Render)
    in
    title_ :: toc :: body


setSelectedId : String -> Render.Settings.Settings -> Render.Settings.Settings
setSelectedId id settings =
    { settings | selectedId = id }


renderSettings : String -> Int -> Render.Settings.Settings
renderSettings id w =
    Render.Settings.makeSettings id 0.38 w


affine : Float -> Float -> Int -> Int
affine a b x =
    a * toFloat x + b |> truncate
