module View.Rendered exposing (view, viewForEditor, viewSmall)

import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Html.Attributes as HtmlAttr
import Parser.Block
import Render.Block
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
                , View.Utility.elementAttribute "id" Config.renderedTextId
                ]
                [ View.Utility.katexCSS
                , E.column [ E.spacing 18, E.width (E.px (width_ - 60)) ]
                    (viewDocument width_ model.counter model.selectedId model.selectedSlug model.editRecord)
                ]


viewSmall : FrontendModel -> Document -> Int -> Int -> Int -> Element FrontendMsg
viewSmall model doc width_ deltaH indexShift =
    let
        editRecord =
            Compiler.DifferentialParser.init model.includedContent doc.language doc.content

        currentDocId =
            Maybe.map .id model.currentDocument |> Maybe.withDefault "???"
    in
    E.column
        [ E.paddingEach { left = 12, right = 12, top = 18, bottom = 96 }
        , Background.color (E.rgb 1.0 1.0 0.9)
        , Style.bgGray 1.0
        , E.width (E.px <| Geometry.indexWidth model.windowWidth)
        , E.height (E.px (Geometry.appHeight model - deltaH + indexShift))
        , Font.size 14
        , E.alignTop
        , E.scrollbarY
        , View.Utility.elementAttribute "id" Config.cheatSheetRenderedTextId
        ]
        [ View.Utility.katexCSS
        , E.column [ E.spacing 4, E.width (E.px (Geometry.indexWidth model.windowWidth - 20)) ]
            (viewDocumentSmall (affine 1.75 -650 (Geometry.indexWidth model.windowWidth)) model.counter currentDocId model.selectedSlug editRecord)
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
                , View.Utility.elementAttribute "id" Config.renderedTextId
                ]
                [ View.Utility.katexCSS
                , E.column [ E.spacing 18, E.width (E.px (width_ - 60)) ]
                    (viewDocument width_ model.counter model.selectedId model.selectedSlug model.editRecord)
                ]



-- HELPERS


{-| Used to view "notebooks", aka collections
-}
viewDocumentSmall windowWidth counter currentDocId selectedSlug editRecord =
    let
        settings =
            renderSettings currentDocId selectedSlug windowWidth

        -- |> (\rs -> { rs | titlePrefix = "small-" })
        title_ : Element FrontendMsg
        title_ =
            Compiler.ASTTools.title editRecord.parsed
                |> (\s ->
                        E.paragraph
                            [ E.htmlAttribute (HtmlAttr.id "title")
                            , Font.size 16
                            , E.paddingEach { top = 0, bottom = 0, left = 0, right = 0 }
                            ]
                            [ E.text s ]
                   )

        body : List (Element FrontendMsg)
        body =
            Render.Markup.renderFromAST counter
                editRecord.accumulator
                settings
                editRecord.parsed
                |> List.map (E.map Render)
    in
    E.row
        [ Background.color (E.rgb 0.8 0.8 1.0)
        , E.paddingEach { left = 8, right = 8, top = 12, bottom = 0 }
        , E.spacing 16
        , E.width E.fill
        ]
        [ title_, E.el [ E.moveUp 6, E.alignRight, E.paddingEach { left = 0, right = 8, top = 0, bottom = 0 } ] Button.closeCollectionsIndex ]
        :: body


viewDocument : Int -> Int -> String -> Maybe String -> Compiler.DifferentialParser.EditRecord -> List (Element FrontendMsg)
viewDocument windowWidth counter selectedId selectedSlug editRecord =
    let
        blockNames =
            Compiler.ASTTools.blockNames editRecord.parsed

        title_ : Element FrontendMsg
        title_ =
            Compiler.ASTTools.title editRecord.parsed
                |> (\s -> E.paragraph [ E.htmlAttribute (HtmlAttr.id "title"), Font.size Config.titleSize ] [ E.text s ])

        runninghead =
            Compiler.ASTTools.runninghead editRecord.parsed
                |> Maybe.map (Parser.Block.setName "runninghead_")
                |> Maybe.map (Render.Block.render counter editRecord.accumulator (renderSettings selectedId selectedSlug windowWidth))
                |> Maybe.withDefault E.none
                |> E.map Render

        banner =
            Compiler.ASTTools.banner editRecord.parsed
                |> Maybe.map (Parser.Block.setName "banner_")
                |> Maybe.map (Render.Block.render counter editRecord.accumulator (renderSettings selectedId selectedSlug windowWidth))
                |> Maybe.withDefault E.none
                |> E.map Render

        toc : Element FrontendMsg
        toc =
            Render.TOC.view counter editRecord.accumulator (renderSettings selectedId selectedSlug windowWidth |> setSelectedId selectedId) editRecord.parsed |> E.map Render

        body : List (Element FrontendMsg)
        body =
            Render.Markup.renderFromAST counter editRecord.accumulator (renderSettings selectedId selectedSlug windowWidth) editRecord.parsed |> List.map (E.map Render)

        titlePart =
            if List.member "banner" blockNames then
                runninghead :: title_ :: banner :: []

            else
                runninghead :: title_ :: []
    in
    if List.member "contents" blockNames then
        titlePart ++ (toc :: body)

    else
        titlePart ++ body


setSelectedId : String -> Render.Settings.Settings -> Render.Settings.Settings
setSelectedId id settings =
    { settings | selectedId = id }


renderSettings : String -> Maybe String -> Int -> Render.Settings.Settings
renderSettings id slug w =
    Render.Settings.makeSettings id slug 0.85 w



-- |> (\settings -> { settings | titlePrefix = "SMALL-" })


affine1 : Float -> Float -> Int -> Int
affine1 a b x =
    a * toFloat x + b |> truncate


affine : Float -> Float -> Int -> Int
affine a b x =
    996



-- 1.0 * toFloat x + 500 |> truncate
