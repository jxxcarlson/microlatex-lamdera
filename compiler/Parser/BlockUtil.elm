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
import Parser.Block exposing (BlockType(..), ExpressionBlock(..), IntermediateBlock(..), RawBlock)
import Parser.Common
import Parser.Error
import Parser.Expr exposing (Expr)
import Parser.Helpers as Helpers
import Parser.Language exposing (Language(..))


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
        , content = ""
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
        , numberOfLines = List.length (String.lines content)
        , id = id
        , tag = tag
        , blockType = blockType
        , content = mapContent parse lineNumber blockType content
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


classify lang block =
    case lang of
        MicroLaTeXLang ->
            MicroLaTeX.Parser.Classify.classify block

        L0Lang ->
            L0.Parser.Classify.classify block


toIntermediateBlock : Language -> (Int -> String -> state) -> (state -> List String) -> RawBlock -> IntermediateBlock
toIntermediateBlock lang parseToState extractMessages block =
    let
        classification =
            classify lang block

        tag =
            Compiler.Util.getItem MicroLaTeXLang "label" block.content

        filteredContent =
            Compiler.Util.eraseItem MicroLaTeXLang "label" tag block.content

        messages =
            parseToState block.lineNumber block.content |> extractMessages
    in
    case classification.blockType of
        Paragraph ->
            makeIntermediateBlock block Nothing [] filteredContent messages classification.blockType

        OrdinaryBlock args ->
            makeOrdinaryIntermediateBlock lang messages block filteredContent classification args

        VerbatimBlock args ->
            makeVerbatimInterMediateBlock lang messages block filteredContent classification args


makeOrdinaryIntermediateBlock lang messages block revisedContent classification args =
    let
        name =
            List.head args |> Maybe.withDefault "anon"

        ( newContent, newMessages ) =
            Parser.Error.ordinaryBlock lang name args messages block.lineNumber revisedContent

        revisedArgs =
            case lang of
                L0Lang ->
                    List.drop 1 args

                MicroLaTeXLang ->
                    classification.args
    in
    makeIntermediateBlock block (List.head args) revisedArgs newContent messages classification.blockType


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


makeVerbatimInterMediateBlock : Language -> List String -> RawBlock -> String -> Classification -> List String -> IntermediateBlock
makeVerbatimInterMediateBlock lang messages block revisedContent classification args =
    let
        ( firstLine, rawContent ) =
            split_ revisedContent

        -- messages =
        -- getVerbatimBlockErrorMessages block rawContent classification state extractMessages firstLine
        content_ =
            fixupVerbatimContent lang rawContent (classification.name |> Maybe.withDefault "((anon))")

        -- Debug.log "content_"
    in
    makeIntermediateBlock block classification.name classification.args content_ messages classification.blockType



-- |> Debug.log "makeVerbatimInterMediateBlock"


makeIntermediateBlock : RawBlock -> Maybe String -> List String -> String -> List String -> BlockType -> IntermediateBlock
makeIntermediateBlock block name args content messages blockType_ =
    IntermediateBlock
        { name = name
        , args = args -- List.drop 1 args
        , indent = block.indent
        , lineNumber = block.lineNumber
        , id = String.fromInt block.lineNumber
        , tag = Compiler.Util.getItem MicroLaTeXLang "label" block.content
        , numberOfLines = block.numberOfLines
        , content = content
        , messages = messages
        , blockType = blockType_
        , sourceText = block.content
        }


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
