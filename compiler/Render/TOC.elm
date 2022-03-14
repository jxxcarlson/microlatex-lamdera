module Render.TOC exposing (view)

import Compiler.ASTTools
import Compiler.Acc exposing (Accumulator)
import Either exposing (Either(..))
import Element exposing (Element)
import Element.Events as Events
import Element.Font as Font
import List.Extra
import Markup
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr)
import Render.Elm
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings
import Render.Utility
import Tree


view : Int -> Accumulator -> Render.Settings.Settings -> Markup.SyntaxTree -> Element Render.Msg.MarkupMsg
view counter acc _ ast =
    case ast |> List.map Tree.flatten |> List.concat |> Compiler.ASTTools.filterBlocksOnName "contents" of
        [] ->
            Element.column [ Element.spacing 8, Element.paddingEach { left = 0, right = 0, top = 0, bottom = 36 } ]
                (prepareFrontMatter counter acc Render.Settings.defaultSettings ast)

        _ ->
            Element.column [ Element.spacing 8, Element.paddingEach { left = 0, right = 0, top = 0, bottom = 36 } ]
                (prepareTOC counter acc Render.Settings.defaultSettings ast)


viewTocItem : Int -> Accumulator -> Render.Settings.Settings -> ExpressionBlock -> Element MarkupMsg
viewTocItem count acc settings (ExpressionBlock { args, content, lineNumber }) =
    case content of
        Left _ ->
            Element.none

        Right exprs ->
            let
                id =
                    String.fromInt lineNumber

                sectionNumber =
                    List.Extra.getAt 1 args
                        |> Maybe.withDefault ""
                        |> (\s -> Element.el [] (Element.text (s ++ ". ")))

                label : Element MarkupMsg
                label =
                    Element.paragraph [ tocIndent args ] (sectionNumber :: List.map (Render.Elm.render count acc settings) exprs)
            in
            Element.el [ Events.onClick (SelectId id) ]
                (Element.link [ Font.color (Element.rgb 0 0 0.8) ] { url = Render.Utility.internalLink id, label = label })


prepareTOC : Int -> Accumulator -> Render.Settings.Settings -> Markup.SyntaxTree -> List (Element MarkupMsg)
prepareTOC count acc settings ast =
    let
        rawToc =
            Compiler.ASTTools.tableOfContents ast

        toc =
            Element.el [ Font.bold, Font.size 18 ] (Element.text "Contents")
                :: (rawToc |> List.map (viewTocItem count acc settings))

        headings =
            getHeadings ast

        titleSize =
            Font.size (round Render.Settings.maxHeadingFontSize)

        subtitleSize =
            Font.size (round (0.7 * Render.Settings.maxHeadingFontSize))

        idAttr =
            Render.Utility.elementAttribute "id" "title"

        title =
            headings.title
                |> Maybe.map (List.map (Render.Elm.render count acc settings) >> Element.paragraph [ titleSize, idAttr ])
                |> Maybe.withDefault Element.none

        subtitle =
            headings.subtitle
                |> Maybe.map (List.map (Render.Elm.render count acc settings) >> Element.paragraph [ subtitleSize, Font.color (Element.rgb 0.4 0.4 0.4) ])
                |> Maybe.withDefault Element.none

        spaceBelow k =
            Element.el [ Element.paddingEach { bottom = k, top = 0, left = 0, right = 0 } ] (Element.text " ")
    in
    if List.length rawToc < 2 then
        title :: subtitle :: []

    else
        title :: subtitle :: spaceBelow 8 :: toc


prepareFrontMatter : Int -> Accumulator -> Render.Settings.Settings -> Markup.SyntaxTree -> List (Element MarkupMsg)
prepareFrontMatter count acc settings ast =
    let
        headings =
            getHeadings ast

        titleSize =
            Font.size (round Render.Settings.maxHeadingFontSize)

        subtitleSize =
            Font.size (round (0.7 * Render.Settings.maxHeadingFontSize))

        idAttr =
            Render.Utility.elementAttribute "id" "title"

        title =
            headings.title
                |> Maybe.map (List.map (Render.Elm.render count acc settings) >> Element.paragraph [ titleSize, idAttr ])
                |> Maybe.withDefault Element.none

        subtitle =
            headings.subtitle
                |> Maybe.map (List.map (Render.Elm.render count acc settings) >> Element.paragraph [ subtitleSize, Font.color (Element.rgb 0.4 0.4 0.4) ])
                |> Maybe.withDefault Element.none
    in
    title :: subtitle :: []


tocIndent args =
    Element.paddingEach { left = tocIndentAux args, right = 0, top = 0, bottom = 0 }


tocIndentAux args =
    case List.head args of
        Nothing ->
            0

        Just str ->
            String.toInt str |> Maybe.withDefault 0 |> (\x -> 12 * x)


getHeadings : Markup.SyntaxTree -> { title : Maybe (List Expr), subtitle : Maybe (List Expr) }
getHeadings ast =
    let
        data =
            ast |> Compiler.ASTTools.titleTOC |> Compiler.ASTTools.toExprRecord

        title : Maybe (List Expr)
        title =
            data
                |> List.filter (\item -> item.blockType == OrdinaryBlock [ "title" ])
                |> List.head
                |> Maybe.map .content

        subtitle =
            data
                |> List.filter (\item -> item.blockType == OrdinaryBlock [ "subtitle" ])
                |> List.head
                |> Maybe.map .content
    in
    { title = title, subtitle = subtitle }
