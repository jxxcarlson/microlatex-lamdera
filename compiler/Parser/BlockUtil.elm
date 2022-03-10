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
    ExpressionBlock
        { name = name
        , args = args
        , indent = indent
        , lineNumber = lineNumber
        , numberOfLines = List.length content
        , id = id
        , tag = tag
        , blockType = blockType
        , content = mapContent parse lineNumber blockType sourceText
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
toIntermediateBlock lang parseToState extractMessages block =
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
    case classification.blockType of
        Paragraph ->
            makeIntermediateBlock block messages

        OrdinaryBlock args ->
            makeOrdinaryIntermediateBlock block messages

        VerbatimBlock args ->
            makeVerbatimInterMediateBlock lang block messages (String.lines filteredContent)


makeOrdinaryIntermediateBlock block messages =
    makeIntermediateBlock block messages


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



-- |> Debug.log "fixupVerbatimContent"


addEnd name str =
    if List.member name Parser.Common.verbatimBlockNames && name /= "code" then
        str ++ "\nend"

    else
        str


makeVerbatimInterMediateBlock : Language -> PrimitiveBlock -> List String -> List String -> IntermediateBlock
makeVerbatimInterMediateBlock lang block messages filteredContent =
    let
        (IntermediateBlock data) =
            makeIntermediateBlock block messages
    in
    IntermediateBlock { data | content = filteredContent }



-- |> Debug.log "makeVerbatimInterMediateBlock"


makeIntermediateBlock : PrimitiveBlock -> List String -> IntermediateBlock
makeIntermediateBlock block messages =
    IntermediateBlock
        { name = block.name
        , args = block.args -- List.drop 1 args
        , indent = block.indent
        , lineNumber = block.lineNumber
        , id = String.fromInt block.lineNumber
        , tag = Compiler.Util.getItem MicroLaTeXLang "label" block.sourceText
        , numberOfLines = List.length block.content
        , content = block.content
        , messages = messages
        , blockType = toBlockType block.blockType block.args
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


split_ : String -> ( String, String )
split_ str_ =
    let
        lines =
            str_ |> String.trim |> String.lines
    in
    case lines of
        first :: rest ->
            ( first, String.join "\n" rest )

        _ ->
            ( "first", "rest" )
