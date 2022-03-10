module Parser.BlockUtil exposing
    ( empty
    , getMessages
    , l0Empty
    , toExpressionBlockFromIntermediateBlock
    , toIntermediateBlock
    )

-- import Parser.Expression

import Compiler.Util
import Either exposing (Either(..))
import L0.Parser.Classify
import MicroLaTeX.Parser.Classify
import Parser.Block exposing (BlockType(..), ExpressionBlock(..), IntermediateBlock(..))
import Parser.Common
import Parser.Error
import Parser.Expr exposing (Expr)
import Parser.Helpers as Helpers
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


toExpressionBlockFromIntermediateBlock : (Int -> String -> List Expr) -> IntermediateBlock -> ExpressionBlock
toExpressionBlockFromIntermediateBlock parse (IntermediateBlock { name, args, indent, lineNumber, id, tag, blockType, content, messages, sourceText }) =
    let
        _ =
            Debug.log "INTERMED" ( args, sourceText )
    in
    ExpressionBlock
        { name = name
        , args = args
        , indent = indent
        , lineNumber = lineNumber
        , numberOfLines = List.length content
        , id = id
        , tag = tag
        , blockType = blockType
        , content = mapContent parse lineNumber blockType (String.join "\n" content |> Debug.log "EFF CONT!")
        , messages = messages
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


toIntermediateBlock : Language -> (Int -> String -> state) -> (state -> List String) -> PrimitiveBlock -> IntermediateBlock
toIntermediateBlock lang parseToState extractMessages ({ name, args, blockType } as block) =
    let
        classification =
            classify lang block

        tag =
            Compiler.Util.getItem MicroLaTeXLang "label" block.sourceText

        filteredContent =
            Compiler.Util.eraseItem MicroLaTeXLang "label" tag block.sourceText

        messages =
            parseToState block.lineNumber block.sourceText |> extractMessages
    in
    makeIntermediateBlock lang block messages


dropLast : List a -> List a
dropLast items =
    let
        n =
            List.length items
    in
    List.take (n - 1) items


dropLastIf : Bool -> List a -> List a
dropLastIf ok items =
    if ok then
        dropLast items

    else
        items


lastItem : List a -> List a
lastItem items =
    let
        n =
            List.length items
    in
    List.drop (n - 1) items


handleLastLine : List String -> List String
handleLastLine content =
    if List.member (lastItem content) [ [ "$$" ], [ "\\end{equation}" ], [ "\\end{aligned}" ] ] then
        dropLast content

    else
        content ++ [ "\\red{end??}" ]


makeIntermediateBlock : Language -> PrimitiveBlock -> List String -> IntermediateBlock
makeIntermediateBlock lang block messages =
    let
        blockType =
            toBlockType block.blockType block.args

        content : List String
        content =
            case blockType of
                Paragraph ->
                    block.content

                OrdinaryBlock _ ->
                    List.drop 1 (normalize block.content)
                        |> dropLastIf (lang == MicroLaTeXLang)

                VerbatimBlock _ ->
                    let
                        tag =
                            Compiler.Util.getItem MicroLaTeXLang "label" block.sourceText

                        adjustedContent =
                            -- TODO: better way of filtering for LaTeX
                            block.content
                                |> normalize
                                |> List.filter
                                    (\line -> not (String.contains "label" line))
                    in
                    List.drop 1 adjustedContent
                        |> handleLastLine

        _ =
            Debug.log "NAMED" ( block.named, ( block.name, block.args, blockType ), block.sourceText )
    in
    IntermediateBlock
        { name = block.name
        , args = block.args
        , indent = block.indent |> Debug.log "INDENT"
        , lineNumber = block.lineNumber
        , id = String.fromInt block.lineNumber
        , tag = Compiler.Util.getItem lang "label" block.sourceText
        , numberOfLines = List.length block.content
        , content = content
        , messages = messages
        , blockType = toBlockType block.blockType (List.drop 1 block.args)
        , sourceText = block.sourceText
        }


normalize : List String -> List String
normalize strs =
    case List.head strs of
        Nothing ->
            strs

        Just "" ->
            List.drop 1 strs

        _ ->
            strs


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


getVerbatimBlockErrorMessages block rawContent classification state extractMessages firstLine =
    case classification.blockType of
        VerbatimBlock [ "math" ] ->
            if String.endsWith "$$" rawContent then
                extractMessages state

            else
                Helpers.prependMessage block.lineNumber "You need to close this math expression with '$$'" (extractMessages state)

        VerbatimBlock [ "code" ] ->
            if String.startsWith "```" firstLine && not (String.endsWith "```" rawContent) then
                Helpers.prependMessage block.lineNumber "You need to close this code block with triple backticks" (extractMessages state)

            else
                extractMessages state

        _ ->
            extractMessages state


fixupVerbatimContent lang rawContent name =
    case lang of
        L0Lang ->
            rawContent

        MicroLaTeXLang ->
            case name of
                "math" ->
                    rawContent

                "equation" ->
                    rawContent |> String.replace "\\begin{equation}\n" "" |> String.replace "\n\\end{equation}" ""

                "aligned" ->
                    rawContent |> String.replace "\\begin{aligned}\n" "" |> String.replace "\n\\end{aligned}" ""

                _ ->
                    rawContent


addEnd name str =
    if List.member name Parser.Common.verbatimBlockNames && name /= "code" then
        str ++ "\nend"

    else
        str
