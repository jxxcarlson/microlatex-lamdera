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
import Parser.Language exposing (Language(..))
import Tree


filterExpressionsOnName : String -> List Expr -> List Expr
filterExpressionsOnName name exprs =
    List.filter (matchExprOnName name) exprs


filterBlocksOnName : String -> List (ExpressionBlock Expr) -> List (ExpressionBlock Expr)
filterBlocksOnName name blocks =
    List.filter (matchBlockName name) blocks


filterOutBlockName : String -> List (ExpressionBlock Expr) -> List (ExpressionBlock Expr)
filterOutBlockName name blocks =
    List.filter (noMatchOnBlockName name) blocks


matchBlockName : String -> ExpressionBlock Expr -> Bool
matchBlockName key (ExpressionBlock { name }) =
    Just key == name


noMatchOnBlockName : String -> ExpressionBlock Expr -> Bool
noMatchOnBlockName key (ExpressionBlock { name }) =
    Just key /= name


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


idOfMatchingBlockContent : String -> ExpressionBlock Expr -> Maybe String
idOfMatchingBlockContent key (ExpressionBlock { sourceText, id }) =
    if String.contains key sourceText then
        Just id

    else
        Nothing


titleOLD : SyntaxTree -> List (ExpressionBlock Expr)
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
    case lang of
        L0Lang ->
            title_ L0Lang ast

        MicroLaTeXLang ->
            ast
                |> root
                |> Maybe.map (filterBlock "title")
                |> Maybe.andThen List.head
                |> Maybe.andThen getText
                |> Maybe.withDefault "((untitled-microLaTeX))"


root : Markup.SyntaxTree -> Maybe (ExpressionBlock Expr)
root syntaxTree =
    Maybe.map Tree.label (List.head syntaxTree)



-- AST: [Tree (ExpressionBlock { args = [], blockType = Paragraph, children = [], content = Right [Expr "title" [Text "<<untitled>>" { begin = 7, end = 18, index = 3 }] { begin = 0, end = 0, index = 0 }], id = "0", indent = 1, lineNumber = 0, messages = [], name = Nothing, numberOfLines = 1, sourceText = "\\title{<<untitled>>}" })


filterBlock : String -> ExpressionBlock Expr -> List Expr
filterBlock key (ExpressionBlock { content }) =
    let
        name : Expr -> String
        name expr =
            case expr of
                Expr name_ _ _ ->
                    name_

                _ ->
                    "_no name_"
    in
    case content of
        Left _ ->
            []

        Right exprList ->
            List.filter (\expr -> String.contains key (name expr)) exprList


extractTextFromSyntaxTreeByKey key syntaxTree =
    syntaxTree |> filterBlocksByArgs key |> expressionBlockToText


tableOfContents : Markup.SyntaxTree -> List (ExpressionBlock Expr)
tableOfContents ast =
    filterBlocksByArgs "section" ast


filterBlocksByArgs : String -> Markup.SyntaxTree -> List (ExpressionBlock Expr)
filterBlocksByArgs key ast =
    ast
        |> List.map Tree.flatten
        |> List.concat
        |> List.filter (matchBlock key)


matchBlock : String -> ExpressionBlock Expr -> Bool
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

        _ ->
            Nothing


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

        Error str ->
            str


expressionBlockToText : List (ExpressionBlock Expr) -> String
expressionBlockToText =
    toExprRecord >> List.map .content >> List.concat >> List.filterMap getText >> String.join " "



-- toExprListList : List L0BlockE -> List (List Expr)


toExprRecord : List (ExpressionBlock Expr) -> List { content : List Expr, blockType : BlockType }
toExprRecord blocks =
    List.map toExprList_ blocks



-- toExprList_ : L0BlockE -> List Expr


toExprList_ (ExpressionBlock { blockType, content }) =
    { content = content |> Either.toList |> List.concat, blockType = blockType }
