module Parser.BlockUtil exposing
    ( empty
    , getMessages
    , l0Empty
    , toBlock
    , toBlockFromIntermediateBlock
    , toExpressionBlockFromIntermediateBlock
    , toIntermediateBlock
    , toL0Block
    )

-- import Parser.Expression

import Compiler.Util
import Either exposing (Either(..))
import L0.Parser.Classify
import MicroLaTeX.Parser.Classify
import Parser.Block exposing (BlockType(..), ExpressionBlock(..), IntermediateBlock(..))
import Parser.Common
import Parser.Error
import Parser.Helpers as Helpers
import Parser.Language exposing (Language(..))
import Tree.BlocksV


type Block
    = Block
        { name : Maybe String
        , args : List String
        , indent : Int
        , lineNumber : Int
        , numberOfLines : Int
        , blockType : BlockType
        , content : String
        , children : List Block
        }


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
        , children = []
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
        , children = []
        , sourceText = "YYY"
        }


getMessages : ExpressionBlock expr -> List String
getMessages ((ExpressionBlock { messages }) as block) =
    messages


toBlock : ExpressionBlock expr -> Tree.BlocksV.Block
toBlock (ExpressionBlock { indent, lineNumber, numberOfLines }) =
    { indent = indent, content = "XXX", lineNumber = lineNumber, numberOfLines = numberOfLines }


toBlockFromIntermediateBlock : IntermediateBlock -> Tree.BlocksV.Block
toBlockFromIntermediateBlock (IntermediateBlock { indent, lineNumber, numberOfLines }) =
    { indent = indent, content = "XXX", lineNumber = lineNumber, numberOfLines = numberOfLines }


toExpressionBlockFromIntermediateBlock : (Int -> String -> List expr) -> IntermediateBlock -> ExpressionBlock expr
toExpressionBlockFromIntermediateBlock parse (IntermediateBlock { name, args, indent, lineNumber, id, tag, blockType, content, messages, children, sourceText }) =
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
        , children = List.map (toExpressionBlockFromIntermediateBlock parse) children
        , sourceText = sourceText
        }


mapContent : (Int -> String -> List expr) -> Int -> BlockType -> String -> Either String (List expr)
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


toIntermediateBlock : Language -> (Int -> String -> state) -> (state -> List String) -> Tree.BlocksV.Block -> IntermediateBlock
toIntermediateBlock lang parseToState extractMessages block =
    let
        classify =
            case lang of
                MicroLaTeXLang ->
                    MicroLaTeX.Parser.Classify.classify

                L0Lang ->
                    L0.Parser.Classify.classify

        blockType =
            classify block

        tag =
            Compiler.Util.getItem MicroLaTeXLang "label" block.content

        revisedContent =
            Compiler.Util.eraseItem MicroLaTeXLang "label" tag block.content

        state =
            parseToState block.lineNumber block.content
    in
    case blockType of
        Paragraph ->
            makeIntermediateBlock block Nothing [] revisedContent (extractMessages state) blockType

        OrdinaryBlock args ->
            let
                name =
                    List.head args |> Maybe.withDefault "anon"

                ( newContent, messages ) =
                    Parser.Error.ordinaryBlock lang name args (extractMessages state) block.lineNumber revisedContent

                --
                --name =
                --    List.head args |> Maybe.withDefault "anon"
                --
                --( firstLine, rawContent_ ) =
                --    if List.member name [ "item", "numbered" ] then
                --        split_ revisedContent
                --
                --    else
                --        split_ revisedContent
                --
                --messages =
                --    if rawContent_ == "" && not (List.member (List.head args |> Maybe.withDefault "!!") bareBlockNames) then
                --        Helpers.prependMessage block.lineNumber ("Write something below the block header (" ++ String.replace "| " "" firstLine ++ ")") (extractMessages state)
                --
                --    else
                --        extractMessages state
                --
                --rawContent =
                --    if rawContent_ == "" && not (List.member (List.head args |> Maybe.withDefault "!!") bareBlockNames) then
                --        case lang of
                --            L0Lang ->
                --                firstLine ++ "\n[red[underline[ ••• (1)]]"
                --
                --            MicroLaTeXLang ->
                --                firstLine ++ "\n\\red{\\underline{ ••• (1)}}"
                --
                --    else
                --        rawContent_
                --
                --endString =
                --    "\\end{" ++ name ++ "}"
                --
                --eraseLastLine str =
                --    let
                --        lines =
                --            str |> String.lines
                --
                --        n =
                --            List.length lines
                --
                --        lastLine =
                --            List.drop (n - 1) lines |> String.join ""
                --    in
                --    if String.left 1 lastLine == "\\" then
                --        lines |> List.take (n - 1) |> String.join "\n"
                --
                --    else
                --        str
                --
                --content_ =
                --    if String.contains endString rawContent then
                --        String.replace endString "" rawContent
                --
                --    else if not (List.member name [ "item", "numbered" ]) && lang == MicroLaTeXLang then
                --        eraseLastLine rawContent ++ "\n\\red{\\underline{ ••• (X)}}"
                --
                --    else
                --        rawContent
                --
                --content =
                --    if List.member name Parser.Common.verbatimBlockNames && not (List.member name [ "item", "numbered" ]) then
                --        content_ ++ "\nend"
                --
                --    else
                --        content_
            in
            makeIntermediateBlock block (List.head args) (List.drop 1 args) newContent messages blockType

        VerbatimBlock args ->
            let
                ( firstLine, rawContent ) =
                    split_ revisedContent

                messages =
                    case blockType of
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

                name =
                    List.head args |> Maybe.withDefault "anon"

                endString =
                    "\\end{" ++ name ++ "}"

                ( revisedName, _, content_ ) =
                    if String.contains endString rawContent then
                        ( name, blockType, String.replace endString "" rawContent |> addEnd )

                    else if not (List.member name [ "math" ]) && lang == MicroLaTeXLang then
                        ( "code", VerbatimBlock [ "code" ], "\\begin{" ++ name ++ "}\n" ++ rawContent ++ "\\red{underline{  ••• (3)}}" )

                    else
                        ( name, blockType, rawContent )

                addEnd str =
                    if List.member name Parser.Common.verbatimBlockNames && name /= "code" then
                        str ++ "\nend"

                    else
                        str
            in
            makeIntermediateBlock block (Just revisedName) (List.drop 1 args) content_ messages blockType


makeIntermediateBlock block name args content messages blockType_ =
    IntermediateBlock
        { name = name
        , args = List.drop 1 args
        , indent = block.indent
        , lineNumber = block.lineNumber
        , id = String.fromInt block.lineNumber
        , tag = Compiler.Util.getItem MicroLaTeXLang "label" block.content
        , numberOfLines = block.numberOfLines
        , content = content
        , messages = messages
        , blockType = blockType_
        , children = []
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



-- ( List.head lines |> Maybe.withDefault "", lines |> List.drop 1 |> String.join "\n" )


toL0Block : (Tree.BlocksV.Block -> BlockType) -> Tree.BlocksV.Block -> Block
toL0Block classify block =
    let
        blockType =
            classify block
    in
    case blockType of
        Paragraph ->
            Block
                { name = Nothing
                , args = []
                , indent = block.indent
                , lineNumber = block.lineNumber
                , numberOfLines = block.numberOfLines
                , content = block.content
                , blockType = blockType
                , children = []
                }

        OrdinaryBlock args ->
            Block
                { name = List.head args
                , args = List.drop 1 args
                , indent = block.indent
                , lineNumber = block.lineNumber
                , numberOfLines = block.numberOfLines
                , content = block.content
                , blockType = blockType
                , children = []
                }

        VerbatimBlock args ->
            Block
                { name = List.head args
                , args = List.drop 1 args
                , indent = block.indent
                , lineNumber = block.lineNumber
                , numberOfLines = block.numberOfLines
                , content = block.content
                , blockType = blockType
                , children = []
                }
