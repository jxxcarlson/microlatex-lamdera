module Render.Block exposing (render)

import Compiler.Acc exposing (Accumulator)
import Dict exposing (Dict)
import Either exposing (Either(..))
import Element exposing (Element)
import Element.Background as Background
import Element.Events as Events
import Element.Font as Font
import Html.Attributes
import List.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr)
import Render.Elm
import Render.Math exposing (DisplayMode(..))
import Render.Msg exposing (L0Msg(..))
import Render.Settings exposing (Settings)
import Render.Utility
import String.Extra


htmlId str =
    Element.htmlAttribute (Html.Attributes.id str)


render : Int -> Accumulator -> Settings -> ExpressionBlock Expr -> Element L0Msg
render count acc settings (ExpressionBlock { name, args, indent, blockType, content, lineNumber, id, children }) =
    case blockType of
        Paragraph ->
            case content of
                Right exprs ->
                    let
                        color =
                            if id == settings.selectedId then
                                Background.color (Element.rgb 0.9 0.9 1.0)

                            else
                                Background.color (Element.rgb 1 1 1)
                    in
                    List.map (Render.Elm.render count acc settings) exprs
                        |> (\x -> Element.paragraph [ color, Events.onClick (SendId id), htmlId id ] x)

                Left _ ->
                    Element.none

        VerbatimBlock _ ->
            case content of
                Right _ ->
                    Element.none

                Left str ->
                    case name of
                        Nothing ->
                            noSuchVerbatimBlock "name" str

                        Just functionName ->
                            case Dict.get functionName verbatimDict of
                                Nothing ->
                                    noSuchVerbatimBlock functionName str

                                Just f ->
                                    f count acc settings args id str

        OrdinaryBlock _ ->
            case content of
                Left _ ->
                    Element.none

                Right exprs ->
                    case name of
                        Nothing ->
                            noSuchOrdinaryBlock count acc settings "name" exprs

                        Just functionName ->
                            case Dict.get functionName blockDict of
                                Nothing ->
                                    env (String.Extra.toTitleCase functionName) count acc settings args id exprs

                                Just f ->
                                    f count acc settings args id exprs


noSuchVerbatimBlock : String -> String -> Element L0Msg
noSuchVerbatimBlock functionName content =
    Element.column [ Element.spacing 4 ]
        [ Element.paragraph [ Font.color (Element.rgb255 180 0 0) ] [ Element.text <| "|| " ++ functionName ++ " ??(8)" ]
        , Element.column [ Element.spacing 4 ] (List.map (\t -> Element.el [] (Element.text t)) (String.lines content))
        ]


noSuchOrdinaryBlock : Int -> Accumulator -> Settings -> String -> List Expr -> Element L0Msg
noSuchOrdinaryBlock count acc settings functionName exprs =
    Element.column [ Element.spacing 4 ]
        [ Element.paragraph [ Font.color (Element.rgb255 180 0 0) ] [ Element.text <| "| " ++ functionName ++ " ??(9) " ]
        , Element.paragraph [] (List.map (Render.Elm.render count acc settings) exprs)
        ]



-- DICT


blockDict : Dict String (Int -> Accumulator -> Settings -> List String -> String -> List Expr -> Element L0Msg)
blockDict =
    Dict.fromList
        [ ( "indent", indented )
        , ( "bibitem", bibitem )
        , ( "heading", heading )
        , ( "section", heading )
        , ( "title", \_ _ _ _ _ _ -> Element.none )
        , ( "subtitle", \_ _ _ _ _ _ -> Element.none )
        , ( "author", \_ _ _ _ _ _ -> Element.none )
        , ( "date", \_ _ _ _ _ _ -> Element.none )
        , ( "defs", \_ _ _ _ _ _ -> Element.none )
        , ( "contents", \_ _ _ _ _ _ -> Element.none )

        --, ( "abstract", env "Abstract" )
        --, ( "theorem", env "Theorem" )
        --, ( "proposition", env "Proposition" )
        --, ( "lemma", env "Lemma" )
        --, ( "corollary", env "Corollary" )
        --, ( "problem", env "Problem" )
        --, ( "remark", env "Remark" )
        --, ( "example", env "Example" )
        --, ( "note", env "Note" )
        , ( "env", env_ )
        , ( "item", item )
        , ( "numbered", numbered )
        ]


verbatimDict : Dict String (Int -> Accumulator -> Settings -> List String -> String -> String -> Element L0Msg)
verbatimDict =
    Dict.fromList
        [ ( "math", renderDisplayMath "$$" )
        , ( "equation", equation )
        , ( "aligned", aligned )
        , ( "code", renderCode )
        , ( "comment", renderComment )
        ]


renderComment : Int -> Accumulator -> Settings -> List String -> String -> String -> Element L0Msg
renderComment _ _ _ _ _ _ =
    Element.none


equation : Int -> Accumulator -> Settings -> List String -> String -> String -> Element L0Msg
equation count acc settings args id str =
    Element.row [ Element.width (Element.px settings.width), Render.Utility.elementAttribute "id" id ]
        [ Element.el [ Element.centerX ] (renderDisplayMath "|| equation" count acc settings args id str)
        , Element.el [ Element.alignRight, Font.size 12, equationLabelPadding ] (Element.text <| "(" ++ Render.Utility.getArg "??(10)" 0 args ++ ")")
        ]


aligned : Int -> Accumulator -> Settings -> List String -> String -> String -> Element L0Msg
aligned count acc settings args id str =
    Element.row [ Element.width (Element.px settings.width), Render.Utility.elementAttribute "id" id ]
        [ Element.el [ Element.centerX ] (renderDisplayMath "|| aligned" count acc settings args id str)
        , Element.el [ Element.alignRight, Font.size 12, equationLabelPadding ] (Element.text <| "(" ++ Render.Utility.getArg "??(11)" 0 args ++ ")")
        ]


equationLabelPadding =
    Element.paddingEach { left = 0, right = 18, top = 0, bottom = 0 }


heading count acc settings args id exprs =
    -- level 1 is reserved for titles
    let
        headingLevel =
            case List.head args of
                Nothing ->
                    3

                Just level ->
                    String.toFloat level |> Maybe.withDefault 2 |> (\x -> x + 1)

        sectionNumber =
            case List.Extra.getAt 1 args of
                Just "-" ->
                    Element.none

                Just s ->
                    Element.el [ Font.size fontSize ] (Element.text (s ++ ". "))

                Nothing ->
                    Element.none

        fontSize =
            Render.Settings.maxHeadingFontSize / sqrt headingLevel |> round
    in
    Element.link
        [ Font.size fontSize
        , Render.Utility.makeId exprs
        , Render.Utility.elementAttribute "id" id
        , Events.onClick (SendId id)
        ]
        { url = Render.Utility.internalLink "TITLE", label = Element.paragraph [] (sectionNumber :: renderWithDefault "| heading" count acc settings exprs) }


renderWithDefault : String -> Int -> Accumulator -> Settings -> List Expr -> List (Element L0Msg)
renderWithDefault default count acc settings exprs =
    if List.isEmpty exprs then
        [ Element.el [ Font.color Render.Settings.redColor, Font.size 14 ] (Element.text default) ]

    else
        List.map (Render.Elm.render count acc settings) exprs


indented count acc settings args id exprs =
    Element.paragraph [ Render.Settings.leftIndentation, Events.onClick (SendId id), Render.Utility.elementAttribute "id" id ]
        (renderWithDefault "| indent" count acc settings exprs)


bibitem count acc settings args id exprs =
    let
        label =
            List.Extra.getAt 1 args |> Maybe.withDefault "??(12)" |> (\s -> "[" ++ s ++ "]")
    in
    Element.row [ Element.alignTop, Render.Utility.elementAttribute "id" id, vspace 0 Render.Settings.topMarginForChildren ]
        [ Element.el
            [ Font.size 14
            , Element.alignTop
            , Font.bold
            , Element.width (Element.px 34)
            ]
            (Element.text label)
        , Element.paragraph [ Element.paddingEach { left = 25, right = 0, top = 0, bottom = 0 }, Events.onClick (SendId id) ]
            (renderWithDefault "bibitem" count acc settings exprs)
        ]


env_ : Int -> Accumulator -> Settings -> List String -> String -> List Expr -> Element L0Msg
env_ count acc settings args id exprs =
    case List.head args of
        Nothing ->
            Element.paragraph [ Render.Utility.elementAttribute "id" id, Font.color Render.Settings.redColor, Events.onClick (SendId id) ] [ Element.text "| env (missing name!)" ]

        Just name ->
            env name count acc settings (List.drop 1 args) id exprs


env : String -> Int -> Accumulator -> Settings -> List String -> String -> List Expr -> Element L0Msg
env name count acc settings args id exprs =
    let
        label =
            args
                |> List.filter (\s -> String.contains "index::" s)
                |> String.join ""
                |> String.replace "index::" ""

        headingString =
            String.join " " (List.filter (\s -> not (String.contains "::" s)) args)

        envHeading =
            name ++ " " ++ label ++ headingString
    in
    Element.column [ Element.spacing 8, Render.Utility.elementAttribute "id" id ]
        [ Element.el [ Font.bold, Events.onClick (SendId id) ] (Element.text envHeading)
        , Element.paragraph [ Font.italic, Events.onClick (SendId id) ]
            (renderWithDefault ("| " ++ name) count acc settings exprs)
        ]


renderDisplayMath : String -> Int -> Accumulator -> Settings -> List String -> String -> String -> Element L0Msg
renderDisplayMath prefix count acc settings args id str =
    let
        w =
            String.fromInt settings.width ++ "px"

        allLines =
            String.lines str

        lines =
            String.lines str |> List.filter (\line -> not (String.left 2 line == "$$")) |> List.filter (\line -> not (String.left 6 line == "[label"))

        n =
            List.length allLines

        lastLine =
            List.Extra.getAt (n - 1) allLines

        leftPadding =
            Element.paddingEach { left = 45, right = 0, top = 0, bottom = 0 }
    in
    if lastLine == Just "$" then
        Element.column [ Events.onClick (SendId id), Font.color Render.Settings.blueColor, leftPadding ]
            (List.map Element.text ("$$" :: List.take (n - 1) lines) ++ [ Element.paragraph [] [ Element.text "$", Element.el [ Font.color Render.Settings.redColor ] (Element.text " another $?") ] ])

    else if lastLine == Just "$$" || lastLine == Just "end" then
        let
            lines_ =
                List.take (n - 1) lines

            adjustedLines =
                if prefix == "|| aligned" then
                    "\\begin{aligned}" :: lines_ ++ [ "\\end{aligned}" ]

                else
                    lines_
        in
        Element.column [ Events.onClick (SendId id), leftPadding ]
            [ Render.Math.mathText count w "id" DisplayMathMode (String.join "\n" adjustedLines) ]

    else
        let
            suffix =
                if prefix == "$$" then
                    "$$"

                else
                    "end"
        in
        Element.column [ Events.onClick (SendId id), Font.color Render.Settings.blueColor, leftPadding ]
            (List.map Element.text (prefix :: List.take n lines) ++ [ Element.paragraph [] [ Element.el [ Font.color Render.Settings.redColor ] (Element.text suffix) ] ])


renderCode : Int -> Accumulator -> Settings -> List String -> String -> String -> Element L0Msg
renderCode count acc settings args id str =
    Element.column
        [ Font.color (Element.rgb255 170 0 250)
        , Font.family
            [ Font.typeface "Inconsolata"
            , Font.monospace
            ]
        , Element.spacing 8
        , Element.paddingEach { left = 24, right = 0, top = 0, bottom = 0 }
        , Events.onClick (SendId id)
        , Render.Utility.elementAttribute "id" id
        ]
        (List.map (\t -> Element.el [] (Element.text t)) (String.lines (String.trim str)))


item count acc settings args id exprs =
    Element.row [ Element.alignTop, Render.Utility.elementAttribute "id" id, vspace 0 12 ]
        [ Element.el [ Font.size 18, Element.alignTop, Element.moveRight 6, Element.width (Element.px 24), Render.Settings.leftIndentation ] (Element.text "•")
        , Element.paragraph [ Render.Settings.leftIndentation, Events.onClick (SendId id) ]
            (renderWithDefault "| item" count acc settings exprs)
        ]


vspace =
    Render.Utility.vspace


numbered count acc settings args id exprs =
    let
        label =
            List.Extra.getAt 0 args |> Maybe.withDefault ""
    in
    Element.row [ Element.alignTop, Render.Utility.elementAttribute "id" id, vspace 0 Render.Settings.topMarginForChildren ]
        [ Element.el
            [ Font.size 14
            , Element.alignTop
            , Element.moveRight 6
            , Element.width (Element.px 24)
            , Render.Settings.leftIndentation
            ]
            (Element.text (label ++ ". "))
        , Element.paragraph [ Render.Settings.leftIndentation, Events.onClick (SendId id) ]
            (renderWithDefault "| numbered" count acc settings exprs)
        ]