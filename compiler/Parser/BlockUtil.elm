module Parser.BlockUtil exposing
    ( empty
    , getMessages
    , l0Empty
    , toEBfromIB
    , toExpressionBlock
    , toIntermediateBlock
    )

-- import Parser.Expression

import Compiler.Util
import Either exposing (Either(..))
import L0.Parser.Classify
import MicroLaTeX.Parser.Classify
import MicroLaTeX.Parser.Expression
import Parser.Block exposing (BlockType(..), ExpressionBlock(..), IntermediateBlock(..))
import Parser.Common
import Parser.Expr exposing (Expr)
import Parser.Language exposing (Language(..))
import Parser.Line exposing (PrimitiveBlockType(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)


type alias Classification =
    { blockType : BlockType, args : List String, name : Maybe String }


empty =
    IntermediateBlock
        { name = Nothing
        , args = []
        , indent = 0
        , lineNumber = 0
        , id = "0"
        , tag = ""
        , numberOfLines = 0
        , blockType = Paragraph
        , content = []
        , messages = []
        , sourceText = "YYY"
        }


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


{-|

    This function transforms an intermediate block (IB) to an expression block (EB),
    carrying forward all fields except for the content field, which is transformed.

    The content of an IB is a string, while the content of an EB is `Either String (List Expr).
    Recall that both IBs and EBs have a field blockType: Paragraph, OrdinaryBlock args, VerbatimBlock args.
    In the case of a verbatim block, the content is of type Left String, while for the other blocks it
    is of type List Expr.

-}
toEBfromIB : (Int -> String -> List Expr) -> IntermediateBlock -> ExpressionBlock
toEBfromIB parse (IntermediateBlock { name, args, indent, lineNumber, id, tag, blockType, content, messages, sourceText }) =
    ExpressionBlock
        { name = name
        , args = args
        , indent = indent
        , lineNumber = lineNumber
        , numberOfLines = List.length content
        , id = id
        , tag = tag
        , blockType = blockType
        , content = mapContent parse lineNumber blockType (String.join "\n" content)
        , messages = messages
        , sourceText = sourceText
        }


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


classify : Language -> PrimitiveBlock -> Parser.Common.Classification
classify lang block =
    case lang of
        MicroLaTeXLang ->
            MicroLaTeX.Parser.Classify.classify block

        L0Lang ->
            L0.Parser.Classify.classify block

        XMarkdownLang ->
            -- TODO: implement this
            L0.Parser.Classify.classify block


toIntermediateBlock : (Int -> String -> state) -> (state -> List String) -> PrimitiveBlock -> IntermediateBlock
toIntermediateBlock parseToState extractMessages ({ name, args, blockType } as block) =
    let
        messages =
            parseToState block.lineNumber block.sourceText |> extractMessages
    in
    makeIntermediateBlock block messages


makeIntermediateBlock : PrimitiveBlock -> List String -> IntermediateBlock
makeIntermediateBlock block messages =
    let
        blockType =
            toBlockType block.blockType (List.drop 1 block.args)

        content =
            case blockType of
                Paragraph ->
                    block.content

                _ ->
                    List.drop 1 block.content
    in
    IntermediateBlock
        { name = block.name
        , args = block.args
        , indent = block.indent
        , lineNumber = block.lineNumber
        , id = String.fromInt block.lineNumber
        , tag = Compiler.Util.getItem MicroLaTeXLang "label" block.sourceText
        , numberOfLines = List.length block.content
        , content = content
        , messages = messages
        , blockType = blockType
        , sourceText = block.sourceText
        }


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
