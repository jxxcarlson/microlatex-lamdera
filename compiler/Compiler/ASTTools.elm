module Compiler.ASTTools exposing
    ( exprListToStringList
    , extractTextFromSyntaxTreeByKey
    , filterBlocksByArgs
    , filterBlocksOnName
    , filterExpressionsOnName
    , getText
    , matchingIdsInAST
    , stringValueOfList
    , tableOfContents
    , title
    , titleOLD
    , toExprRecord
    )

import Either exposing (Either(..))
import Markup exposing (SyntaxTree)
import Maybe.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))
import Parser.Language exposing (Language)
import Tree


filterExpressionsOnName : String -> List Expr -> List Expr
filterExpressionsOnName name exprs =
    List.filter (matchExprOnName name) exprs


filterBlocksOnName : String -> List ExpressionBlock -> List ExpressionBlock
filterBlocksOnName name blocks =
    List.filter (matchBlockName name) blocks


matchBlockName : String -> ExpressionBlock -> Bool
matchBlockName key (ExpressionBlock { name }) =
    Just key == name


matchExprOnName : String -> Expr -> Bool
matchExprOnName name expr =
    case expr of
        Expr name2 _ _ ->
            name == name2

        Verbatim name2 _ _ ->
            name == name2

        _ ->
            False


matchingIdsInAST : String -> SyntaxTree -> List String
matchingIdsInAST key ast =
    ast |> List.map Tree.flatten |> List.concat |> List.filterMap (idOfMatchingBlockContent key)


idOfMatchingBlockContent : String -> ExpressionBlock -> Maybe String
idOfMatchingBlockContent key (ExpressionBlock { sourceText, id }) =
    if String.contains key sourceText then
        Just id

    else
        Nothing


titleOLD : SyntaxTree -> List ExpressionBlock
titleOLD ast =
    filterBlocksByArgs "title" ast


title_ lang ast =
    let
        mBlock =
            ast
                |> List.map Tree.flatten
                |> List.concat
                |> filterBlocksOnName "title"
                |> List.head
    in
    case mBlock of
        Nothing ->
            "(title)"

        Just (ExpressionBlock { content }) ->
            case content of
                Left str ->
                    str

                Right exprList ->
                    List.map getText exprList |> Maybe.Extra.values |> String.join ""


title : Language -> Markup.SyntaxTree -> String
title lang ast =
    title_ lang ast



-- AST: [Tree (ExpressionBlock { args = [], blockType = Paragraph, children = [], content = Right [Expr "title" [Text "<<untitled>>" { begin = 7, end = 18, index = 3 }] { begin = 0, end = 0, index = 0 }], id = "0", indent = 1, lineNumber = 0, messages = [], name = Nothing, numberOfLines = 1, sourceText = "\\title{<<untitled>>}" })


extractTextFromSyntaxTreeByKey key syntaxTree =
    syntaxTree |> filterBlocksByArgs key |> expressionBlockToText


tableOfContents : Markup.SyntaxTree -> List ExpressionBlock
tableOfContents ast =
    filterBlocksByArgs "section" ast


filterBlocksByArgs : String -> Markup.SyntaxTree -> List ExpressionBlock
filterBlocksByArgs key ast =
    ast
        |> List.map Tree.flatten
        |> List.concat
        |> List.filter (matchBlock key)


matchBlock : String -> ExpressionBlock -> Bool
matchBlock key (ExpressionBlock { blockType }) =
    case blockType of
        Paragraph ->
            False

        OrdinaryBlock args ->
            List.any (String.contains key) args

        VerbatimBlock args ->
            List.any (String.contains key) args


exprListToStringList : List Expr -> List String
exprListToStringList exprList =
    List.map getText exprList
        |> Maybe.Extra.values
        |> List.map String.trim
        |> List.filter (\s -> s /= "")


getText : Expr -> Maybe String
getText text =
    case text of
        Text str _ ->
            Just str

        Verbatim _ str _ ->
            Just (String.replace "`" "" str)

        Expr _ expressions _ ->
            List.map getText expressions |> Maybe.Extra.values |> String.join " " |> Just


stringValueOfList : List Expr -> String
stringValueOfList textList =
    String.join " " (List.map stringValue textList)


stringValue : Expr -> String
stringValue text =
    case text of
        Text str _ ->
            str

        Expr _ textList _ ->
            String.join " " (List.map stringValue textList)

        Verbatim _ str _ ->
            str


expressionBlockToText : List ExpressionBlock -> String
expressionBlockToText =
    toExprRecord >> List.map .content >> List.concat >> List.filterMap getText >> String.join " "



-- toExprListList : List L0BlockE -> List (List Expr)


toExprRecord : List ExpressionBlock -> List { content : List Expr, blockType : BlockType }
toExprRecord blocks =
    List.map toExprList_ blocks



-- toExprList_ : L0BlockE -> List Expr


toExprList_ (ExpressionBlock { blockType, content }) =
    { content = content |> Either.toList |> List.concat, blockType = blockType }
