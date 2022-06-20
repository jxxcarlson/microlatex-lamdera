module Render.Export.LaTeX exposing (export, exportExpr, rawExport)

import Compiler.ASTTools as ASTTools
import Compiler.Lambda as Lambda
import Dict exposing (Dict)
import Either exposing (Either(..))
import List.Extra
import Maybe.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))
import Parser.Forest exposing (Forest)
import Parser.Helpers exposing (Step(..), loop)
import Render.Export.Image
import Render.Export.Preamble
import Render.Export.Util
import Render.Settings exposing (Settings, defaultSettings)
import Render.Utility as Utility
import Tree


export : Settings -> Forest ExpressionBlock -> String
export settings ast =
    let
        rawBlockNames =
            ASTTools.rawBlockNames ast

        blockNames =
            List.Extra.unique rawBlockNames

        expressionNames =
            ASTTools.expressionNames ast

        imageList : List String
        imageList =
            getImageUrls ast

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


getImageUrls : Forest ExpressionBlock -> List String
getImageUrls forest =
    getImageUrls_ forest ++ getImageUrlsFromQuiver forest


getImageUrls_ : Forest ExpressionBlock -> List String
getImageUrls_ ast =
    ast
        |> List.map Tree.flatten
        |> List.concat
        |> List.map (\(ExpressionBlock { content }) -> Either.rightToMaybe content |> Maybe.withDefault [])
        |> List.concat
        |> ASTTools.filterExpressionsOnName "image"
        |> List.map ASTTools.getText
        |> Maybe.Extra.values


getImageUrlsFromQuiver : List (Tree.Tree ExpressionBlock) -> List String
getImageUrlsFromQuiver ast =
    ast
        |> List.map Tree.flatten
        |> List.concat
        |> List.filter (\block -> Parser.Block.getName block == Just "quiver")
        |> List.map getImageUrl
        |> Maybe.Extra.values


getImageUrl : ExpressionBlock -> Maybe String
getImageUrl (ExpressionBlock { content }) =
    case content of
        Either.Left str ->
            getImageUrl_ str

        Either.Right _ ->
            Nothing


getImageUrl_ : String -> Maybe String
getImageUrl_ str =
    let
        maybePair =
            case String.split "---" str of
                a :: b :: [] ->
                    Just ( a, b )

                _ ->
                    Nothing
    in
    case maybePair of
        Nothing ->
            Nothing

        Just ( imageData, latexData ) ->
            let
                arguments : List String
                arguments =
                    String.words imageData
            in
            List.head arguments


rawExport : Settings -> Forest ExpressionBlock -> String
rawExport settings ast =
    ast
        |> List.map Tree.flatten
        |> List.concat
        |> ASTTools.filterNotBlocksOnName "runninghead"
        |> List.map Parser.Block.condenseUrls
        |> encloseLists
        |> List.map (shiftSection 1)
        |> List.map (exportBlock settings)
        |> String.join "\n\n"


type Status
    = InsideItemizedList
    | OutsideList
    | InsideNumberedList


encloseLists : List ExpressionBlock -> List ExpressionBlock
encloseLists blocks =
    loop { status = OutsideList, inputList = blocks, outputList = [], itemNumber = 0 } nextStep |> List.reverse


type alias State =
    { status : Status, inputList : List ExpressionBlock, outputList : List ExpressionBlock, itemNumber : Int }


nextStep : State -> Step State (List ExpressionBlock)
nextStep state =
    case List.head state.inputList of
        Nothing ->
            Done state.outputList

        Just block ->
            Loop (nextState block state)


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


nextState : ExpressionBlock -> State -> State
nextState ((ExpressionBlock { name }) as block) state =
    case ( state.status, name ) of
        -- ITEMIZED LIST
        ( OutsideList, Just "item" ) ->
            { state | status = InsideItemizedList, itemNumber = 1, outputList = block :: beginItemizedBlock :: state.outputList, inputList = List.drop 1 state.inputList }

        ( InsideItemizedList, Just "item" ) ->
            { state | outputList = block :: state.outputList, itemNumber = state.itemNumber + 1, inputList = List.drop 1 state.inputList }

        ( InsideItemizedList, _ ) ->
            { state | status = OutsideList, itemNumber = 0, outputList = block :: endItemizedBlock :: state.outputList, inputList = List.drop 1 state.inputList }

        -- NUMBERED LIST
        ( OutsideList, Just "numbered" ) ->
            { state | status = InsideNumberedList, itemNumber = 1, outputList = block :: beginNumberedBlock :: state.outputList, inputList = List.drop 1 state.inputList }

        ( InsideNumberedList, Just "numbered" ) ->
            { state | outputList = block :: state.outputList, itemNumber = state.itemNumber + 1, inputList = List.drop 1 state.inputList }

        ( InsideNumberedList, _ ) ->
            { state | status = OutsideList, itemNumber = 0, outputList = block :: endNumberedBlock :: state.outputList, inputList = List.drop 1 state.inputList }

        --- OUTSIDE
        ( OutsideList, _ ) ->
            { state | outputList = block :: state.outputList, inputList = List.drop 1 state.inputList }


exportBlock : Settings -> ExpressionBlock -> String
exportBlock settings ((ExpressionBlock { blockType, name, args, content }) as block) =
    case blockType of
        Paragraph ->
            case content of
                Left str ->
                    mapChars2 str

                Right exprs_ ->
                    exportExprList settings exprs_

        OrdinaryBlock args_ ->
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

        VerbatimBlock args_ ->
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
                            environment "anon" str

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
        [ ( "link", link )
        , ( "ilink", ilink )
        , ( "index_", blindIndex )
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

        -- UNIMPLEMENTED
        , ( "chart", \_ _ _ -> "chart: unimplemented" )
        , ( "svg", \_ _ _ -> "svg: unimplemented" )
        , ( "datatable", \_ _ _ -> "datatable: unimplemented" )

        --
        , ( "section", \_ args body -> section args body )
        , ( "item", \_ _ body -> macro1 "item" body )
        , ( "numbered", \_ _ body -> macro1 "item" body )
        , ( "beginBlock", \_ _ _ -> "\\begin{itemize}" )
        , ( "endBlock", \_ _ _ -> "\\end{itemize}" )
        , ( "beginNumberedBlock", \_ _ _ -> "\\begin{enumerate}" )
        , ( "endNumberedBlock", \_ _ _ -> "\\end{enumerate}" )
        , ( "mathmacros", \_ args body -> body ++ "\nHa ha ha!" )
        , ( "setcounter", \_ args body -> setcounter args body )
        ]


verbatimExprDict =
    Dict.fromList
        [ ( "code", code )
        ]



-- END DICTIONARIES


code : Settings -> List Expr -> String
code _ exprs =
    Render.Export.Util.getOneArg exprs |> fixChars


link : Settings -> List Expr -> String
link s exprs =
    let
        args =
            Render.Export.Util.getTwoArgs exprs
    in
    [ "\\href{", args.second, "}{", args.first, "}" ] |> String.join ""


ilink : Settings -> List Expr -> String
ilink s exprs =
    let
        args =
            Render.Export.Util.getTwoArgs exprs
    in
    [ "\\href{", "https://scripta.io/s/", args.second, "}{", args.first, "}" ] |> String.join ""


blindIndex : Settings -> List Expr -> String
blindIndex s exprs =
    let
        args =
            Render.Export.Util.getTwoArgs exprs
    in
    -- TODO
    [] |> String.join ""


setcounter : List String -> String -> String
setcounter args body =
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

        Just macro ->
            body |> fixChars



-- HELPERS


tagged name body =
    "\\" ++ name ++ "{" ++ body ++ "}"


environment name body =
    [ tagged "begin" name, body, tagged "end" name ] |> String.join "\n"
