module Render.Markup exposing (getMessages, renderFromAST, renderFromString, render_)

import Compiler.Acc exposing (Accumulator)
import Element exposing (Element)
import Markup exposing (SyntaxTree)
import Parser.BlockUtil as BlockUtil
import Parser.Language exposing (Language)
import Render.Block
import Render.Msg exposing (MarkupMsg)
import Render.Settings exposing (Settings)
import Tree exposing (Tree)


renderFromString : Language -> Int -> Accumulator -> Settings -> String -> List (Element MarkupMsg)
renderFromString lang count acc settings str =
    str |> Markup.parse lang |> renderFromAST count acc settings


render_ : Accumulator -> SyntaxTree -> List (Element MarkupMsg)
render_ acc ast =
    renderFromAST 0 acc Render.Settings.defaultSettings ast


renderFromAST : Int -> Accumulator -> Settings -> SyntaxTree -> List (Element MarkupMsg)
renderFromAST count accumulator settings ast =
    ast
        |> List.map (Tree.map (Render.Block.render count accumulator settings))
        |> List.map unravel


getMessages : SyntaxTree -> List String
getMessages syntaxTree =
    syntaxTree
        |> List.map Tree.flatten
        |> List.concat
        |> List.map BlockUtil.getMessages
        |> List.concat


{-| Comment on this!
-}
unravel : Tree (Element MarkupMsg) -> Element MarkupMsg
unravel tree =
    let
        children =
            Tree.children tree
    in
    if List.isEmpty children then
        Tree.label tree

    else
        Element.column []
            --  Render.Settings.leftIndentation,
            [ Tree.label tree
            , Element.column [ Element.paddingEach { top = Render.Settings.topMarginForChildren, left = Render.Settings.leftIndent, right = 0, bottom = 0 } ] (List.map unravel children)
            ]
