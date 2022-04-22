module Render.LaTeX exposing (export, exportExpr, rawExport)

import Compiler.ASTTools as ASTTools
import Compiler.Lambda as Lambda
import Dict exposing (Dict)
import Either exposing (Either(..))
import Maybe.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr(..))
import Parser.Forest exposing (Forest)
import Parser.Helpers exposing (Step(..), loop)
import Render.Settings exposing (Settings, defaultSettings)
import Render.Utility as Utility
import Tree


export : Settings -> Forest ExpressionBlock -> String
export settings ast =
    let
        imageList : List String
        imageList =
            getImageUrls ast
    in
    preamble (ASTTools.extractTextFromSyntaxTreeByKey "title" ast)
        (ASTTools.extractTextFromSyntaxTreeByKey "author" ast)
        (ASTTools.extractTextFromSyntaxTreeByKey "date" ast)
        ++ "\n\n"
        ++ rawExport settings ast
        ++ "\n\n\\end{document}\n"


getImageUrls : Forest ExpressionBlock -> List String
getImageUrls ast =
    ast
        |> List.map Tree.flatten
        |> List.concat
        |> List.map (\(ExpressionBlock { content }) -> Either.rightToMaybe content |> Maybe.withDefault [])
        |> List.concat
        |> ASTTools.filterExpressionsOnName "image"
        |> List.map ASTTools.getText
        |> Maybe.Extra.values


rawExport : Settings -> Forest ExpressionBlock -> String
rawExport settings ast =
    ast
        |> List.map Tree.flatten
        |> List.concat
        |> List.map Parser.Block.condenseUrls
        |> encloseLists
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
                            if name_ == "defs" then
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


macroDict : Dict String (Settings -> List Expr -> String)
macroDict =
    Dict.fromList
        [ ( "link", link )
        , ( "ilink", ilink )
        , ( "index_", blindIndex )
        , ( "code", code )
        , ( "image", image )
        ]


blockDict : Dict String (Settings -> List String -> String -> String)
blockDict =
    Dict.fromList
        [ ( "title", \_ _ _ -> "" )
        , ( "subtitle", \_ _ _ -> "" )
        , ( "author", \_ _ _ -> "" )
        , ( "date", \_ _ _ -> "" )
        , ( "contents", \_ _ _ -> "" )
        , ( "section", \_ args body -> section args body )
        , ( "item", \_ _ body -> macro1 "item" body )
        , ( "numbered", \_ _ body -> macro1 "item" body )
        , ( "beginBlock", \_ _ _ -> "\\begin{itemize}" )
        , ( "endBlock", \_ _ _ -> "\\end{itemize}" )
        , ( "beginNumberedBlock", \_ _ _ -> "\\begin{enumerate}" )
        , ( "endNumberedBlock", \_ _ _ -> "\\end{enumerate}" )
        , ( "mathmacros", \_ args body -> body ++ "\nHa ha ha!" )
        ]


verbatimExprDict =
    Dict.fromList
        [ ( "code", code )
        ]



-- END DICTIONARIES


getArgs : List Expr -> List String
getArgs =
    ASTTools.exprListToStringList >> List.map String.words >> List.concat >> List.filter (\x -> x /= "")


getOneArg : List Expr -> String
getOneArg exprs =
    case List.head (getArgs exprs) of
        Nothing ->
            ""

        Just str ->
            str


getTwoArgs : List Expr -> { first : String, second : String }
getTwoArgs exprs =
    let
        args =
            getArgs exprs

        n =
            List.length args

        first =
            List.take (n - 1) args |> String.join " "

        second =
            List.drop (n - 1) args |> String.join ""
    in
    { first = first, second = second }


code : Settings -> List Expr -> String
code _ exprs =
    getOneArg exprs |> fixChars


link : Settings -> List Expr -> String
link s exprs =
    let
        args =
            getTwoArgs exprs
    in
    [ "\\href{", args.second, "}{", args.first, "}" ] |> String.join ""


ilink : Settings -> List Expr -> String
ilink s exprs =
    let
        args =
            getTwoArgs exprs
    in
    [ "\\href{", "https://l0-lab-demo.lamdera.app/i/", args.second, "}{", args.first, "}" ] |> String.join ""


image : Settings -> List Expr -> String
image s exprs =
    let
        args =
            getOneArg exprs |> String.words
    in
    case List.head args of
        Nothing ->
            "ERROR IN IMAGE"

        Just url ->
            [ "\\imagecenter{", url, "}" ] |> String.join ""


blindIndex : Settings -> List Expr -> String
blindIndex s exprs =
    let
        args =
            getTwoArgs exprs
    in
    -- TODO
    [] |> String.join ""


section : List String -> String -> String
section args body =
    case Utility.getArg "4" 0 args of
        "1" ->
            macro1 "section" body

        "2" ->
            macro1 "subsection" body

        "3" ->
            macro1 "subsubsection" body

        _ ->
            macro1 "subheading" body


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



-- PREAMBLE


preamble : String -> String -> String -> String
preamble title author date =
    """
\\documentclass[11pt, oneside]{article}

%% Packages
\\usepackage{geometry}
\\geometry{letterpaper}
\\usepackage{changepage}   % for the adjustwidth environment
\\usepackage{graphicx}
\\usepackage{wrapfig}
\\graphicspath{ {image/} }
\\usepackage{amssymb}
\\usepackage{amsmath}
\\usepackage{amscd}
\\usepackage{hyperref}
\\hypersetup{
    colorlinks=true,
    linkcolor=blue,
    filecolor=magenta,
    urlcolor=blue,
}
\\usepackage{xcolor}
\\usepackage{soul}


%% Commands
\\newcommand{\\code}[1]{{\\tt #1}}
\\newcommand{\\ellie}[1]{\\href{#1}{Link to Ellie}}
% \\newcommand{\\image}[3]{\\includegraphics[width=3cm]{#1}}

\\newcommand{\\imagecenter}[1]{
   \\medskip
   \\begin{figure}
   \\centering
    \\includegraphics[width=12cm,height=12cm,keepaspectratio]{#1}
    \\vglue0pt
    \\end{figure}
    \\medskip
}

\\newcommand{\\imagefloatright}[3]{
    \\begin{wrapfigure}{R}{0.30\\textwidth}
    \\includegraphics[width=0.30\\textwidth]{#1}
    \\caption{#2}
    \\end{wrapfigure}
}

\\newcommand{\\imagefloatleft}[3]{
    \\begin{wrapfigure}{L}{0.3-\\textwidth}
    \\includegraphics[width=0.30\\textwidth]{#1}
    \\caption{#2}
    \\end{wrapfigure}
}

\\newcommand{\\italic}[1]{{\\sl #1}}
\\newcommand{\\strong}[1]{{\\bf #1}}
\\newcommand{\\subheading}[1]{{\\bf #1}\\par}
\\newcommand{\\ilink}[2]{\\href{{https://l0-lab.lamdera.app/p/#1}}{#2}}
\\newcommand{\\red}[1]{\\textcolor{red}{#1}}
\\newcommand{\\blue}[1]{\\textcolor{blue}{#1}}
\\newcommand{\\violet}[1]{\\textcolor{violet}{#1}}
\\newcommand{\\remote}[1]{\\textcolor{red}{#1}}
\\newcommand{\\local}[1]{\\textcolor{blue}{#1}}
\\newcommand{\\highlight}[1]{\\hl{#1}}
\\newcommand{\\note}[2]{\\textcolor{blue}{#1}{\\hl{#1}}}
\\newcommand{\\strike}[1]{\\st{#1}}
\\newcommand{\\term}[1]{{\\sl #1}}
\\newcommand{\\dollarSign}[0]{{\\$}}

\\newcommand{\\backTick}[0]{\\`{}}
\\newtheorem{remark}{Remark}
\\newcommand{\\comment}[1]{}
\\newcommand{\\innertableofcontents}{}

%% Theorems
\\newtheorem{theorem}{Theorem}
\\newtheorem{axiom}{Axiom}
\\newtheorem{lemma}{Lemma}
\\newtheorem{proposition}{Proposition}
\\newtheorem{corollary}{Corollary}
\\newtheorem{definition}{Definition}
\\newtheorem{example}{Example}
\\newtheorem{exercise}{Exercise}
\\newtheorem{problem}{Problem}
\\newtheorem{exercises}{Exercises}
\\newcommand{\\bs}[1]{$\\backslash$#1}
\\newcommand{\\texarg}[1]{\\{#1\\}}

\\newcommand{\\termx}[1]{}

%% Environments
\\renewenvironment{quotation}
  {\\begin{adjustwidth}{2cm}{} \\footnotesize}
  {\\end{adjustwidth}}

\\def\\changemargin#1#2{\\list{}{\\rightmargin#2\\leftmargin#1}\\item[]}
\\let\\endchangemargin=\\endlist

\\renewenvironment{indent}
  {\\begin{adjustwidth}{0.75cm}{}}
  {\\end{adjustwidth}}


\\definecolor{mypink1}{rgb}{0.858, 0.188, 0.478}
\\definecolor{mypink2}{RGB}{219, 48, 122}


%% NEWCOMMAND

\\newcommand{\\fontRGB}[4]{
    \\definecolor{mycolor}{RGB}{#1, #2, #3}
    \\textcolor{mycolor}{#4}
    }

\\newcommand{\\highlightRGB}[4]{
    \\definecolor{mycolor}{RGB}{#1, #2, #3}
    \\sethlcolor{mycolor}
    \\hl{#4}
     \\sethlcolor{yellow}
    }

\\newcommand{\\gray}[2]{
\\definecolor{mygray}{gray}{#1}
\\textcolor{mygray}{#2}
}

\\newcommand{\\white}[1]{\\gray{1}[#1]}
\\newcommand{\\medgray}[1]{\\gray{0.5}[#1]}
\\newcommand{\\black}[1]{\\gray{0}[#1]}

% Spacing
\\parindent0pt
\\parskip5pt


\\begin{document}


\\title{""" ++ title ++ """}
\\author{""" ++ author ++ """}
\\date{""" ++ date ++ """}

\\maketitle

\\tableofcontents

"""
