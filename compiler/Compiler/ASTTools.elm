module Compiler.ASTTools exposing
    ( blockNames
    , existsBlockWithName
    , exprListToStringList
    , expressionNames
    , extractTextFromSyntaxTreeByKey
    , filterASTOnName
    , filterBlocksByArgs
    , filterBlocksOnName
    , filterExpressionsOnName
    , filterExpressionsOnName_
    , filterForestForExpressionsWithName
    , filterOutExpressionsOnName
    , getText
    , matchingIdsInAST
    , normalize
    , stringValueOfList
    , tableOfContents
    , title
    , titleTOC
    , toExprRecord
    )

import Either exposing (Either(..))
import List.Extra
import Maybe.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))
import Parser.Forest exposing (Forest)
import Tree


normalize : Either String (List Expr) -> Either String (List Expr)
normalize exprs =
    case exprs of
        Right ((Text _ _) :: rest) ->
            Right rest

        _ ->
            exprs


filterForestForExpressionsWithName : String -> Forest Expr -> List Expr
filterForestForExpressionsWithName name forest =
    filterExpressionsOnName name (List.map Tree.flatten forest |> List.concat)


blockNames : List (Tree.Tree Parser.Block.ExpressionBlock) -> List String
blockNames forest =
    List.map Tree.flatten forest
        |> List.concat
        |> List.map Parser.Block.getName
        |> Maybe.Extra.values
        |> List.Extra.unique
        |> List.sort


expressionNames : List (Tree.Tree ExpressionBlock) -> List String
expressionNames forest =
    List.map Tree.flatten forest
        |> List.concat
        |> List.map Parser.Block.getContent
        |> List.concat
        |> List.map Parser.Expr.getName
        |> Maybe.Extra.values
        |> List.Extra.unique
        |> List.sort


filterExpressionsOnName : String -> List Expr -> List Expr
filterExpressionsOnName name exprs =
    List.filter (matchExprOnName name) exprs


filterOutExpressionsOnName : String -> List Expr -> List Expr
filterOutExpressionsOnName name exprs =
    List.filter (\expr -> not (matchExprOnName name expr)) exprs


filterExpressionsOnName_ : String -> List Expr -> List Expr
filterExpressionsOnName_ name exprs =
    List.filter (matchExprOnName_ name) exprs


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


matchExprOnName_ : String -> Expr -> Bool
matchExprOnName_ name expr =
    case expr of
        Expr name2 _ _ ->
            String.startsWith name name2

        Verbatim name2 _ _ ->
            String.startsWith name name2

        _ ->
            False


matchingIdsInAST : String -> Forest ExpressionBlock -> List String
matchingIdsInAST key ast =
    ast |> List.map Tree.flatten |> List.concat |> List.filterMap (idOfMatchingBlockContent key)


idOfMatchingBlockContent : String -> ExpressionBlock -> Maybe String
idOfMatchingBlockContent key (ExpressionBlock { sourceText, id }) =
    if String.contains key sourceText then
        Just id

    else
        Nothing


titleTOC : Forest ExpressionBlock -> List ExpressionBlock
titleTOC ast =
    filterBlocksByArgs "title" ast


existsBlockWithName : List (Tree.Tree ExpressionBlock) -> String -> Bool
existsBlockWithName ast name =
    let
        mBlock =
            ast
                |> List.map Tree.flatten
                |> List.concat
                |> filterBlocksOnName name
                |> List.head
    in
    case mBlock of
        Nothing ->
            False

        Just _ ->
            True


{-| Return the text content of the first element with the given name
-}
filterASTOnName : List (Tree.Tree ExpressionBlock) -> String -> List String
filterASTOnName ast name =
    let
        mBlock =
            ast
                |> List.map Tree.flatten
                |> List.concat
                |> filterBlocksOnName name
                |> List.head
    in
    case mBlock of
        Nothing ->
            []

        Just (ExpressionBlock { content }) ->
            case content of
                Left str ->
                    [ str ]

                Right exprList ->
                    List.map getText exprList |> Maybe.Extra.values


title_ : List (Tree.Tree ExpressionBlock) -> String
title_ ast =
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


title : Forest ExpressionBlock -> String
title ast =
    title_ ast


extractTextFromSyntaxTreeByKey : String -> Forest ExpressionBlock -> String
extractTextFromSyntaxTreeByKey key syntaxTree =
    syntaxTree |> filterBlocksByArgs key |> expressionBlockToText


tableOfContents : Forest ExpressionBlock -> List ExpressionBlock
tableOfContents ast =
    filterBlocksOnName "section" (List.map Tree.flatten ast |> List.concat)


filterBlocksByArgs : String -> Forest ExpressionBlock -> List ExpressionBlock
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


toExprList_ : ExpressionBlock -> { content : List Expr, blockType : BlockType }
toExprList_ (ExpressionBlock { blockType, content }) =
    { content = content |> Either.toList |> List.concat, blockType = blockType }
