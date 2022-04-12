module View.CheatSheet exposing (view)

import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Document
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes as HtmlAttr
import Render.Markup
import Render.Settings
import Render.TOC
import Types exposing (DocumentHandling(..), FrontendModel, FrontendMsg(..), PopupState(..))
import View.Button as Button
import View.Color as Color
import View.Utility


view : FrontendModel -> E.Element Types.FrontendMsg
view model =
    if model.popupState == CheatSheetPopup then
        viewCheatSheet model

    else
        E.none


viewCheatSheet : FrontendModel -> E.Element Types.FrontendMsg
viewCheatSheet model =
    case model.currentCheatsheet of
        Just doc ->
            let
                editRecord =
                    Compiler.DifferentialParser.init doc.language doc.content

                w =
                    max (model.windowWidth // 3) 500

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
                       , View.Utility.htmlId "__CHEATSHEET_RENDERED_TEXT__"
                       ]
                )
                (viewDocument w h model.counter "--" editRecord)

        Nothing ->
            E.none


viewDocument windowWidth windowHeight counter selectedId editRecord =
    let
        title_ : E.Element Types.FrontendMsg
        title_ =
            Compiler.ASTTools.title editRecord.parsed
                |> (\s -> E.paragraph [ E.htmlAttribute (HtmlAttr.id "title"), Font.size Config.titleSize ] [ E.text s ])

        toc : E.Element Types.FrontendMsg
        toc =
            Render.TOC.view counter editRecord.accumulator (renderSettings selectedId windowWidth |> setSelectedId selectedId) editRecord.parsed |> E.map Render

        body : List (E.Element Types.FrontendMsg)
        body =
            Render.Markup.renderFromAST counter editRecord.accumulator (renderSettings selectedId windowWidth) editRecord.parsed |> List.map (E.map Types.Render)
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


row heading body =
    E.row [ E.spacing 12, Font.size 14 ]
        [ E.el [ Font.bold, E.width (E.px 60) ] (E.text heading)
        , E.paragraph [ E.width (E.px 250) ] [ E.text body ]
        ]


style2 =
    [ E.spacing 18
    , E.padding 25
    , Font.size 14
    , Border.width 1
    , Background.color Color.white
    ]


style =
    [ E.moveRight 128
    , E.moveDown 25
    , E.spacing 18
    , E.width (E.px 450)
    , E.height (E.px 700)
    , E.padding 25
    , Font.size 14
    , Background.color Color.paleViolet
    ]


label str =
    E.el [ Font.size 16, Font.bold, E.width (E.px 60) ] (E.text str)
