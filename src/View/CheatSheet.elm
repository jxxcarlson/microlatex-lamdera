module View.CheatSheet exposing (view)

import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes as HtmlAttr
import Parser.Block
import Render.Block
import Render.Markup
import Render.Settings
import Render.TOC
import Types exposing (FrontendModel, FrontendMsg(..), PopupState(..))
import View.Color as Color
import View.Utility


view : FrontendModel -> E.Element Types.FrontendMsg
view model =
    if model.popupState == GuidesPopup then
        viewCheatSheet model

    else if model.popupState == ManualsPopup then
        viewManual model

    else
        E.none


bgColor =
    E.rgb 0.955 0.955 1


minimumWidth =
    450


viewManual : FrontendModel -> E.Element Types.FrontendMsg
viewManual model =
    case model.currentManual of
        Just doc ->
            let
                editRecord =
                    Compiler.DifferentialParser.init model.includedContent doc.language doc.content

                w =
                    min (model.windowWidth // 3) minimumWidth

                h =
                    model.windowHeight - 166
            in
            E.column
                (style2
                    ++ [ Font.size 14
                       , E.width (E.px w)
                       , E.height (E.px h)
                       , E.scrollbarY
                       , E.paddingEach { left = 18, right = 18, top = 36, bottom = 36 }
                       , Background.color bgColor
                       , View.Utility.htmlId Config.cheatSheetRenderedTextId
                       ]
                )
                (viewDocument w model.counter model.selectedId editRecord)

        Nothing ->
            E.none


viewCheatSheet : FrontendModel -> E.Element Types.FrontendMsg
viewCheatSheet model =
    case model.currentManual of
        Just doc ->
            let
                editRecord =
                    Compiler.DifferentialParser.init model.includedContent doc.language doc.content

                w =
                    min (model.windowWidth // 3) minimumWidth

                h =
                    model.windowHeight - 166
            in
            E.column
                (style2
                    ++ [ Font.size 14
                       , E.width (E.px w)
                       , E.height (E.px h)
                       , E.scrollbarY
                       , E.paddingEach { left = 18, right = 18, top = 36, bottom = 36 }
                       , Background.color bgColor
                       , View.Utility.htmlId Config.cheatSheetRenderedTextId
                       ]
                )
                (viewDocument w model.counter model.selectedId editRecord)

        Nothing ->
            E.none


viewDocument windowWidth counter selectedId editRecord =
    let
        title_ : E.Element Types.FrontendMsg
        title_ =
            Compiler.ASTTools.title editRecord.parsed
                |> (\s -> E.paragraph [ E.htmlAttribute (HtmlAttr.id "manual-title"), Font.size Config.titleSize ] [ E.text s ])

        runninghead =
            Compiler.ASTTools.runninghead editRecord.parsed
                |> Maybe.map (Parser.Block.setName "runninghead_")
                |> Maybe.map (Render.Block.render counter editRecord.accumulator (renderSettings selectedId (Just "selectedSlug") windowWidth))
                |> Maybe.withDefault E.none
                |> E.map Render

        toc : E.Element Types.FrontendMsg
        toc =
            Render.TOC.view counter editRecord.accumulator (renderSettings selectedId Nothing windowWidth |> setSelectedId selectedId) editRecord.parsed |> E.map Render

        body : List (E.Element Types.FrontendMsg)
        body =
            Render.Markup.renderFromAST counter editRecord.accumulator (renderSettings selectedId Nothing windowWidth) editRecord.parsed |> List.map (E.map Types.Render)
    in
    runninghead :: title_ :: toc :: body


setSelectedId : String -> Render.Settings.Settings -> Render.Settings.Settings
setSelectedId id settings =
    { settings | selectedId = id }


renderSettings : String -> Maybe String -> Int -> Render.Settings.Settings
renderSettings id slug w =
    let
        s =
            Render.Settings.makeSettings id slug 0.85 w
    in
    { s | backgroundColor = bgColor, titlePrefix = "manual-" }


style2 =
    [ E.spacing 18
    , E.padding 25
    , Font.size 14
    , Border.width 1
    , Background.color Color.white
    ]
