module Render.Export.LaTeX exposing (export, exportExpr, rawExport)

import Compiler.ASTTools as ASTTools
import Compiler.Lambda as Lambda
import Dict exposing (Dict)
import Either exposing (Either(..))
import List.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))
import Parser.Forest exposing (Forest)
import Parser.Helpers exposing (Step(..), loop)
import Render.Export.Image
import Render.Export.Preamble
import Render.Export.Util
import Render.Settings exposing (Settings)
import Render.Utility as Utility
import Tree exposing (Tree)


export : Settings -> Forest ExpressionBlock -> String
export settings ast =
    let
        rawBlockNames =
            ASTTools.rawBlockNames ast

        expressionNames =
            ASTTools.expressionNames ast

        -- imageList : List String
        get ast_ name_ =
            ASTTools.filterASTOnName ast_ name_ |> String.join " "
    in
    Render.Export.Preamble.make
        rawBlockNames
        expressionNames
        (get ast "title")
        (get ast "author")
        (get ast "date")
        ++ tableofcontents rawBlockNames
        ++ "\n\n"
        ++ rawExport settings ast
        ++ "\n\n\\end{document}\n"


tableofcontents rawBlockNames_ =
    if List.length (List.filter (\name -> name == "section") rawBlockNames_) > 1 then
        "\n\n\\tableofcontents"

    else
        ""


shiftSection : Int -> ExpressionBlock -> ExpressionBlock
shiftSection delta ((ExpressionBlock data) as block) =
    if data.name == Just "section" then
        case data.args of
            level :: rest ->
                case String.toInt level of
                    Nothing ->
                        block

                    Just kk ->
                        let
                            newLevel =
                                String.fromInt (kk + delta)
                        in
                        ExpressionBlock { data | args = newLevel :: rest }

            _ ->
                block

    else
        block


exportTree : Settings -> Tree ExpressionBlock -> String
exportTree settings tree =
    case Tree.children tree of
        [] ->
            exportBlock settings (Tree.label tree)

        children ->
            let
                renderedChildren : List String
                renderedChildren =
                    List.map (exportTree settings) children |> List.map String.lines |> List.concat

                root =
                    exportBlock settings (Tree.label tree) |> String.lines
            in
            case List.Extra.unconsLast root of
                Nothing ->
                    ""

                Just ( lastLine, precedingLines ) ->
                    precedingLines ++ renderedChildren ++ [ lastLine ] |> String.join "\n"


rawExport : Settings -> List (Tree ExpressionBlock) -> String
rawExport settings ast =
    ast
        |> ASTTools.filterForestOnLabelNames (\name -> not (name == Just "runninghead"))
        |> Parser.Forest.map Parser.Block.condenseUrls
        |> encloseLists
        |> Parser.Forest.map (shiftSection 1)
        |> List.map (exportTree settings)
        |> String.join "\n\n"


type Status
    = InsideItemizedList
    | OutsideList
    | InsideNumberedList


encloseLists : Forest ExpressionBlock -> Forest ExpressionBlock
encloseLists blocks =
    loop { status = OutsideList, input = blocks, output = [], itemNumber = 0 } nextStep |> List.reverse


type alias State =
    { status : Status, input : Forest ExpressionBlock, output : Forest ExpressionBlock, itemNumber : Int }


nextStep : State -> Step State (Forest ExpressionBlock)
nextStep state =
    case List.head state.input of
        Nothing ->
            Done state.output

        Just tree ->
            Loop (nextState tree state)


beginItemizedBlock : ExpressionBlock
beginItemizedBlock =
    ExpressionBlock
        { args = []
        , blockType = OrdinaryBlock [ "beginBlock" ]
        , content = Right [ Text "itemize" { begin = 0, end = 7, index = 0, id = "" } ]
        , messages = []
        , id = "0"
        , tag = ""
        , indent = 1
        , lineNumber = 0
        , name = Just "beginBlock"
        , numberOfLines = 2
        , sourceText = "| beginBlock\nitemize"
        }


endItemizedBlock : ExpressionBlock
endItemizedBlock =
    ExpressionBlock
        { args = []
        , blockType = OrdinaryBlock [ "endBlock" ]
        , content = Right [ Text "itemize" { begin = 0, end = 7, index = 0, id = "" } ]
        , messages = []
        , id = "0"
        , tag = ""
        , indent = 1
        , lineNumber = 0
        , name = Just "endBlock"
        , numberOfLines = 2
        , sourceText = "| endBlock\nitemize"
        }


beginNumberedBlock : ExpressionBlock
beginNumberedBlock =
    ExpressionBlock
        { args = []
        , blockType = OrdinaryBlock [ "beginNumberedBlock" ]
        , content = Right [ Text "enumerate" { begin = 0, end = 7, index = 0, id = "begin" } ]
        , messages = []
        , id = "0"
        , tag = ""
        , indent = 1
        , lineNumber = 0
        , name = Just "beginNumberedBlock"
        , numberOfLines = 2
        , sourceText = "| beginBlock\nitemize"
        }


endNumberedBlock : ExpressionBlock
endNumberedBlock =
    ExpressionBlock
        { args = []
        , blockType = OrdinaryBlock [ "endNumberedBlock" ]
        , content = Right [ Text "enumerate" { begin = 0, end = 7, index = 0, id = "end" } ]
        , messages = []
        , id = "0"
        , tag = ""
        , indent = 1
        , lineNumber = 0
        , name = Just "endNumberedBlock"
        , numberOfLines = 2
        , sourceText = "| endBlock\nitemize"
        }


nextState : Tree ExpressionBlock -> State -> State
nextState tree state =
    let
        name_ =
            case Tree.label tree of
                ExpressionBlock { name } ->
                    name
    in
    case ( state.status, name_ ) of
        -- ITEMIZED LIST
        ( OutsideList, Just "item" ) ->
            { state | status = InsideItemizedList, itemNumber = 1, output = tree :: Tree.singleton beginItemizedBlock :: state.output, input = List.drop 1 state.input }

        ( InsideItemizedList, Just "item" ) ->
            { state | output = tree :: state.output, itemNumber = state.itemNumber + 1, input = List.drop 1 state.input }

        ( InsideItemizedList, _ ) ->
            { state | status = OutsideList, itemNumber = 0, output = tree :: Tree.singleton endItemizedBlock :: state.output, input = List.drop 1 state.input }

        -- NUMBERED LIST
        ( OutsideList, Just "numbered" ) ->
            { state | status = InsideNumberedList, itemNumber = 1, output = tree :: Tree.singleton beginNumberedBlock :: state.output, input = List.drop 1 state.input }

        ( InsideNumberedList, Just "numbered" ) ->
            { state | output = tree :: state.output, itemNumber = state.itemNumber + 1, input = List.drop 1 state.input }

        ( InsideNumberedList, _ ) ->
            { state | status = OutsideList, itemNumber = 0, output = tree :: Tree.singleton endNumberedBlock :: state.output, input = List.drop 1 state.input }

        --- OUTSIDE
        ( OutsideList, _ ) ->
            { state | output = tree :: state.output, input = List.drop 1 state.input }


exportBlock : Settings -> ExpressionBlock -> String
exportBlock settings (ExpressionBlock { blockType, name, args, content }) =
    case blockType of
        Paragraph ->
            case content of
                Left str ->
                    mapChars2 str

                Right exprs_ ->
                    exportExprList settings exprs_

        OrdinaryBlock _ ->
            case content of
                Left _ ->
                    ""

                Right exprs_ ->
                    let
                        name_ =
                            name |> Maybe.withDefault "anon"
                    in
                    case Dict.get name_ blockDict of
                        Just f ->
                            f settings args (exportExprList settings exprs_)

                        Nothing ->
                            if name_ == "textmacros" then
                                renderDefs settings exprs_

                            else
                                environment name_ (exportExprList settings exprs_)

        VerbatimBlock _ ->
            case content of
                Left str ->
                    case name of
                        Just "math" ->
                            -- TODO: there should be a trailing "$$"
                            [ "$$", str, "$$" ] |> String.join "\n"

                        Just "equation" ->
                            -- TODO: there should be a trailing "$$"
                            -- TODO: equation numbers and label
                            [ "\\begin{equation}", str, "\\end{equation}" ] |> String.join "\n"

                        Just "aligned" ->
                            -- TODO: equation numbers and label
                            [ "\\begin{align}", str, "\\end{align}" ] |> String.join "\n"

                        Just "code" ->
                            str |> fixChars |> (\s -> "\\begin{verbatim}\n" ++ s ++ "\n\\end{verbatim}")

                        Just "mathmacros" ->
                            str

                        Just "quiver" ->
                            let
                                data =
                                    String.split "---" str
                                        |> List.drop 1
                                        |> String.join ""
                            in
                            data

                        Just "tikz" ->
                            let
                                data =
                                    String.split "---" str
                                        |> List.drop 1
                                        |> String.join ""
                                        |> String.lines
                                        |> List.map
                                            (\line ->
                                                if line == "" then
                                                    "%"

                                                else
                                                    line
                                            )
                                        |> String.join "\n"
                            in
                            [ "\\[\n", data, "\n\\]" ]
                                |> String.join ""

                        Just "comment" ->
                            ""

                        _ ->
                            Maybe.withDefault "??" name ++ ": export of this block is unimplemented"

                Right _ ->
                    "???(13)"


fixChars str =
    str |> String.replace "{" "\\{" |> String.replace "}" "\\}"


renderDefs settings exprs =
    "%% Macro definitions from Markup text:\n"
        ++ exportExprList settings exprs


mapChars1 : String -> String
mapChars1 str =
    str
        |> String.replace "\\term_" "\\termx"


mapChars2 : String -> String
mapChars2 str =
    str
        |> String.replace "_" "\\_"



-- BEGIN DICTIONARIES


functionDict : Dict String String
functionDict =
    Dict.fromList
        [ ( "italic", "textit" )
        , ( "i", "textit" )
        , ( "bold", "textbf" )
        , ( "b", "textbf" )
        , ( "image", "imagecenter" )
        , ( "contents", "tableofcontents" )
        ]



-- MACRODICT


macroDict : Dict String (Settings -> List Expr -> String)
macroDict =
    Dict.fromList
        [ ( "link", \_ -> link )
        , ( "ilink", \_ -> ilink )
        , ( "index_", \_ _ -> blindIndex )
        , ( "code", code )
        , ( "image", Render.Export.Image.export )
        ]



-- BLOCKDICT


blockDict : Dict String (Settings -> List String -> String -> String)
blockDict =
    Dict.fromList
        [ ( "title", \_ _ _ -> "" )
        , ( "subtitle", \_ _ _ -> "" )
        , ( "author", \_ _ _ -> "" )
        , ( "date", \_ _ _ -> "" )
        , ( "contents", \_ _ _ -> "" )
        , ( "comment", \_ _ _ -> "" )
        , ( "tags", \_ _ _ -> "" )

        --
        , ( "section", \_ args body -> section args body )
        , ( "item", \_ _ body -> macro1 "item" body )
        , ( "numbered", \_ _ body -> macro1 "item" body )
        , ( "beginBlock", \_ _ _ -> "\\begin{itemize}" )
        , ( "endBlock", \_ _ _ -> "\\end{itemize}" )
        , ( "beginNumberedBlock", \_ _ _ -> "\\begin{enumerate}" )
        , ( "endNumberedBlock", \_ _ _ -> "\\end{enumerate}" )
        , ( "mathmacros", \_ _ body -> body ++ "\nHa ha ha!" )
        , ( "setcounter", \_ args _ -> setcounter args )
        ]


verbatimExprDict =
    Dict.fromList
        [ ( "code", code )
        ]



-- END DICTIONARIES


code : Settings -> List Expr -> String
code _ exprs =
    Render.Export.Util.getOneArg exprs |> fixChars


link : List Expr -> String
link exprs =
    let
        args =
            Render.Export.Util.getTwoArgs exprs
    in
    [ "\\href{", args.second, "}{", args.first, "}" ] |> String.join ""


ilink : List Expr -> String
ilink exprs =
    let
        args =
            Render.Export.Util.getTwoArgs exprs
    in
    [ "\\href{", "https://scripta.io/s/", args.second, "}{", args.first, "}" ] |> String.join ""


blindIndex : String
blindIndex =
    ""


setcounter : List String -> String
setcounter args =
    [ "\\setcounter{section}{", Utility.getArg "0" 0 args, "}" ] |> String.join ""


section : List String -> String -> String
section args body =
    let
        suffix =
            case List.Extra.getAt 1 args of
                Nothing ->
                    ""

                Just "-" ->
                    "*"

                Just _ ->
                    ""
    in
    case Utility.getArg "4" 0 args of
        "1" ->
            macro1 ("section" ++ suffix) body

        "2" ->
            macro1 ("subsection" ++ suffix) body

        "3" ->
            macro1 ("subsubsection" ++ suffix) body

        _ ->
            macro1 ("subheading" ++ suffix) body


macro1 : String -> String -> String
macro1 name arg =
    if name == "math" then
        "$" ++ arg ++ "$"

    else if name == "group" then
        arg

    else if name == "tags" then
        ""

    else
        case Dict.get name functionDict of
            Nothing ->
                "\\" ++ name ++ "{" ++ mapChars2 (String.trimLeft arg) ++ "}"

            Just realName ->
                "\\" ++ realName ++ "{" ++ mapChars2 (String.trimLeft arg) ++ "}"


exportExprList : Settings -> List Expr -> String
exportExprList settings exprs =
    List.map (exportExpr settings) exprs |> String.join "" |> mapChars1


exportExpr : Settings -> Expr -> String
exportExpr settings expr =
    case expr of
        Expr name exps_ _ ->
            if name == "lambda" then
                case Lambda.extract expr of
                    Just lambda ->
                        Lambda.toString (exportExpr settings) lambda

                    Nothing ->
                        "Error extracting lambda"

            else
                case Dict.get name macroDict of
                    Just f ->
                        f settings exps_

                    Nothing ->
                        macro1 name (List.map (exportExpr settings) exps_ |> String.join " ")

        Text str _ ->
            mapChars2 str

        Verbatim name body _ ->
            renderVerbatim name body


renderVerbatim : String -> String -> String
renderVerbatim name body =
    case Dict.get name verbatimExprDict of
        Nothing ->
            macro1 name body

        Just _ ->
            body |> fixChars



-- HELPERS


tagged name body =
    "\\" ++ name ++ "{" ++ body ++ "}"


environment name body =
    [ tagged "begin" name, body, tagged "end" name ] |> String.join "\n"
