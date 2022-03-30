module Parser.BlockUtil exposing
    ( getMessages
    , l0Empty
    , toExpressionBlock
    )

-- import Parser.Expression

import Compiler.Util
import Either exposing (Either(..))
import MicroLaTeX.Parser.Expression
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr)
import Parser.Language exposing (Language(..))
import Parser.Line exposing (PrimitiveBlockType(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)


l0Empty =
    ExpressionBlock
        { name = Nothing
        , args = []
        , indent = 0
        , lineNumber = 0
        , id = "0"
        , tag = ""
        , numberOfLines = 0
        , blockType = Paragraph
        , content = Left "YYY"
        , messages = []
        , sourceText = "YYY"
        }


getMessages : ExpressionBlock -> List String
getMessages ((ExpressionBlock { messages }) as block) =
    messages


toExpressionBlock : (Int -> String -> List Expr) -> PrimitiveBlock -> ExpressionBlock
toExpressionBlock parse { name, args, indent, lineNumber, blockType, content, sourceText } =
    let
        blockType_ =
            toBlockType blockType (List.drop 1 args)

        content_ =
            case blockType_ of
                Paragraph ->
                    content

                _ ->
                    List.drop 1 content
    in
    ExpressionBlock
        { name = name
        , args = args
        , indent = indent
        , lineNumber = lineNumber
        , numberOfLines = List.length content
        , id = String.fromInt lineNumber
        , tag = Compiler.Util.getItem MicroLaTeXLang "label" sourceText
        , blockType = blockType_
        , content = mapContent parse lineNumber blockType_ (String.join "\n" content_)
        , messages = MicroLaTeX.Parser.Expression.parseToState lineNumber sourceText |> MicroLaTeX.Parser.Expression.extractMessages
        , sourceText = sourceText
        }


mapContent : (Int -> String -> List Expr) -> Int -> BlockType -> String -> Either String (List Expr)
mapContent parse lineNumber blockType content =
    case blockType of
        Paragraph ->
            Right (parse lineNumber content)

        OrdinaryBlock _ ->
            Right (parse lineNumber content)

        VerbatimBlock _ ->
            let
                content_ =
                    if blockType == VerbatimBlock [ "code" ] then
                        Left (String.replace "```" "" content)

                    else
                        Left content
            in
            content_


toBlockType : PrimitiveBlockType -> List String -> BlockType
toBlockType pbt args =
    case pbt of
        PBParagraph ->
            Paragraph

        PBOrdinary ->
            OrdinaryBlock args

        PBVerbatim ->
            VerbatimBlock args



-- UNUSED
