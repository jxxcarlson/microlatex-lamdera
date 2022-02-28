module Render.Markup exposing (getMessages, renderFromAST, renderFromString, render_)

import Compiler.Acc exposing (Accumulator)
import Element exposing (Element)
import Markup exposing (SyntaxTree)
import Parser.BlockUtil as BlockUtil
import Parser.Language exposing (Language)
import Render.Block
import Render.Msg exposing (L0Msg)
import Render.Settings exposing (Settings)
import Tree exposing (Tree)


isVerbatimLine : String -> Bool
isVerbatimLine str =
    String.left 2 str == "||"


renderFromString : Language -> Int -> Accumulator -> Settings -> String -> List (Element L0Msg)
renderFromString lang count acc settings str =
    str |> Markup.parse lang |> renderFromAST count acc settings


render_ : Accumulator -> SyntaxTree -> List (Element L0Msg)
render_ acc ast =
    renderFromAST 0 acc Render.Settings.defaultSettings ast


renderFromAST : Int -> Accumulator -> Settings -> SyntaxTree -> List (Element L0Msg)
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
unravel : Tree (Element L0Msg) -> Element L0Msg
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
