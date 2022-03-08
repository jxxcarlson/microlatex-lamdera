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
import Parser.MathMacro
import Render.Elm
import Render.Math exposing (DisplayMode(..))
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings exposing (Settings)
import Render.Utility
import String.Extra


htmlId str =
    Element.htmlAttribute (Html.Attributes.id str)


render : Int -> Accumulator -> Settings -> ExpressionBlock -> Element MarkupMsg
render count acc settings (ExpressionBlock { name, args, blockType, content, id }) =
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


noSuchVerbatimBlock : String -> String -> Element MarkupMsg
noSuchVerbatimBlock functionName content =
    Element.column [ Element.spacing 4 ]
        [ Element.paragraph [ Font.color (Element.rgb255 180 0 0) ] [ Element.text <| "|| " ++ functionName ++ " ??(8)" ]
        , Element.column [ Element.spacing 4 ] (List.map (\t -> Element.el [] (Element.text t)) (String.lines content))
        ]


noSuchOrdinaryBlock : Int -> Accumulator -> Settings -> String -> List Expr -> Element MarkupMsg
noSuchOrdinaryBlock count acc settings functionName exprs =
    Element.column [ Element.spacing 4 ]
        [ Element.paragraph [ Font.color (Element.rgb255 180 0 0) ] [ Element.text <| "| " ++ functionName ++ " ??(9) " ]
        , Element.paragraph [] (List.map (Render.Elm.render count acc settings) exprs)
        ]



-- DICT


blockDict : Dict String (Int -> Accumulator -> Settings -> List String -> String -> List Expr -> Element MarkupMsg)
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
        , ( "env", env_ )
        , ( "item", item )
        , ( "desc", desc )
        , ( "numbered", numbered )
        , ( "index", index )
        , ( "setcounter", \_ _ _ _ _ _ -> Element.none )
        ]


verbatimDict : Dict String (Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg)
verbatimDict =
    Dict.fromList
        [ ( "math", renderDisplayMath_ )
        , ( "equation", equation )
        , ( "aligned", aligned )
        , ( "code", renderCode )
        , ( "comment", renderComment )
        , ( "mathmacros", renderComment )
        ]


renderComment : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderComment _ _ _ _ _ _ =
    Element.none


equation : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
equation count acc settings args id str =
    Element.row [ Element.width (Element.px settings.width), Render.Utility.elementAttribute "id" id ]
        [ Element.el [ Element.centerX ] (renderDisplayMath "|| equation" count acc settings args id str)
        , Element.el [ Element.alignRight, Font.size 12, equationLabelPadding ] (Element.text <| "(" ++ Render.Utility.getArg "??(10)" 0 args ++ ")")
        ]


aligned : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
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
        ([ Font.size fontSize
         , Render.Utility.makeId exprs
         , Render.Utility.elementAttribute "id" id
         , Events.onClick (SendId id)
         ]
            ++ highlightAttrs id settings
        )
        { url = Render.Utility.internalLink "TITLE", label = Element.paragraph [] (sectionNumber :: renderWithDefault "| heading" count acc settings exprs) }


renderWithDefault : String -> Int -> Accumulator -> Settings -> List Expr -> List (Element MarkupMsg)
renderWithDefault default count acc settings exprs =
    if List.isEmpty exprs then
        [ Element.el [ Font.color Render.Settings.redColor, Font.size 14 ] (Element.text default) ]

    else
        List.map (Render.Elm.render count acc settings) exprs


indented count acc settings _ id exprs =
    Element.paragraph ([ Render.Settings.leftIndentation, Events.onClick (SendId id), Render.Utility.elementAttribute "id" id ] ++ highlightAttrs id settings)
        (renderWithDefault "| indent" count acc settings exprs)


bibitem count acc settings args id exprs =
    let
        label =
            List.Extra.getAt 1 args |> Maybe.withDefault "??(12)" |> (\s -> "[" ++ s ++ "]")
    in
    Element.row ([ Element.alignTop, Render.Utility.elementAttribute "id" id, vspace 0 Render.Settings.topMarginForChildren ] ++ highlightAttrs id settings)
        [ Element.el
            [ Font.size 14
            , Element.alignTop
            , Font.bold
            , Element.width (Element.px 34)
            ]
            (Element.text label)
        , Element.paragraph ([ Element.paddingEach { left = 25, right = 0, top = 0, bottom = 0 }, Events.onClick (SendId id) ] ++ highlightAttrs id settings)
            (renderWithDefault "bibitem" count acc settings exprs)
        ]


env_ : Int -> Accumulator -> Settings -> List String -> String -> List Expr -> Element MarkupMsg
env_ count acc settings args id exprs =
    case List.head args of
        Nothing ->
            Element.paragraph [ Render.Utility.elementAttribute "id" id, Font.color Render.Settings.redColor, Events.onClick (SendId id) ] [ Element.text "| env (missing name!)" ]

        Just name ->
            env name count acc settings (List.drop 1 args) id exprs


env : String -> Int -> Accumulator -> Settings -> List String -> String -> List Expr -> Element MarkupMsg
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
    Element.column ([ Element.spacing 8, Render.Utility.elementAttribute "id" id ] ++ highlightAttrs id settings)
        [ Element.el [ Font.bold, Events.onClick (SendId id) ] (Element.text envHeading)
        , Element.paragraph [ Font.italic, Events.onClick (SendId id) ]
            (renderWithDefault ("| " ++ name) count acc settings exprs)
        ]


renderDisplayMath_ : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderDisplayMath_ count acc settings _ id str =
    let
        w =
            String.fromInt settings.width ++ "px"

        allLines =
            String.lines str

        n =
            List.length allLines

        filteredLines =
            -- lines of math text to be rendered: filter stuff out
            String.lines str
                |> List.filter (\line -> not (String.left 2 line == "$$"))
                |> List.filter (\line -> not (String.left 6 line == "[label"))
                |> List.filter (\line -> line /= "")
    in
    Element.column []
        [ Render.Math.mathText count w id DisplayMathMode (filteredLines |> String.join "\n") ]


renderDisplayMath : String -> Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderDisplayMath prefix count acc settings _ id str =
    let
        w =
            String.fromInt settings.width ++ "px"

        allLines =
            String.lines str

        n =
            List.length allLines

        lastLine =
            List.Extra.getAt (n - 1) allLines

        filteredLines =
            -- lines of math text to be rendered: filter stuff out
            String.lines str
                |> List.filter (\line -> not (String.left 2 line == "$$"))
                |> List.filter (\line -> not (String.left 6 line == "[label"))
                |> Debug.log "LINES"

        leftPadding =
            Element.paddingEach { left = 45, right = 0, top = 0, bottom = 0 }
    in
    if lastLine == Just "$" then
        -- handle error
        Element.column [ Events.onClick (SendId id), Font.color Render.Settings.blueColor, leftPadding ]
            (List.map Element.text ("$$" :: List.take (n - 1) filteredLines) ++ [ Element.paragraph [] [ Element.text "$", Element.el [ Font.color Render.Settings.redColor ] (Element.text " another $?") ] ])

    else if lastLine == Just "$$" || lastLine == Just "end" then
        let
            _ =
                Debug.log "HAPPY PATH"

            lines_ =
                List.take (n - 1) filteredLines |> Debug.log "LINES_"

            attrs =
                if id == settings.selectedId then
                    [ Events.onClick (SendId id), leftPadding, Background.color (Element.rgb 0.8 0.8 1.0) ]

                else
                    [ Events.onClick (SendId id), leftPadding ]

            deleteTrailingSlashes str_ =
                if String.right 2 str_ == "\\\\" then
                    String.dropRight 2 str_

                else
                    str_

            adjustedLines_ =
                List.map (deleteTrailingSlashes >> Parser.MathMacro.evalStr acc.mathMacroDict) lines_
                    |> List.filter (\line -> line /= "")
                    |> List.map (\line -> line ++ "\\\\")

            adjustedLines =
                if prefix == "|| aligned" then
                    "\\begin{aligned}" :: adjustedLines_ ++ [ "\\end{aligned}" ]

                else if prefix == "|| equation" then
                    "\\begin{equation}" :: "\\nonumber" :: adjustedLines_ ++ [ "\\end{equation}" ]

                else
                    lines_

            content =
                String.join "\n" adjustedLines
        in
        Element.column attrs
            [ Render.Math.mathText count w id DisplayMathMode content ]

    else
        let
            suffix =
                if prefix == "$$" then
                    "$$"

                else
                    "end"
        in
        Element.column [ Events.onClick (SendId id), Font.color Render.Settings.blueColor, leftPadding ]
            (List.map Element.text (prefix :: List.take n filteredLines) ++ [ Element.paragraph [] [ Element.el [ Font.color Render.Settings.redColor ] (Element.text suffix) ] ])


highlightAttrs id settings =
    if id == settings.selectedId then
        [ Events.onClick (SendId id), Background.color (Element.rgb 0.8 0.8 1.0) ]

    else
        [ Events.onClick (SendId id) ]


renderCode : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderCode _ _ _ _ id str =
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


item count acc settings _ id exprs =
    Element.row ([ Element.alignTop, Render.Utility.elementAttribute "id" id, vspace 0 12 ] ++ highlightAttrs id settings)
        [ Element.el [ Font.size 18, Element.alignTop, Element.moveRight 6, Element.width (Element.px 24), Render.Settings.leftIndentation ] (Element.text "•")
        , Element.paragraph [ Render.Settings.leftIndentation, Events.onClick (SendId id) ]
            (renderWithDefault "| item" count acc settings exprs)
        ]


desc count acc settings args id exprs =
    let
        label : String
        label =
            String.join " " args
    in
    Element.row ([ Element.alignTop, Render.Utility.elementAttribute "id" id, vspace 0 Render.Settings.topMarginForChildren ] ++ highlightAttrs id settings)
        [ Element.el [ Font.bold, Element.alignTop, Element.width (Element.px 100) ] (Element.text label)
        , Element.paragraph [ Render.Settings.leftIndentation, Events.onClick (SendId id) ]
            (renderWithDefault "| desc" count acc settings exprs)
        ]


vspace =
    Render.Utility.vspace


numbered count acc settings args id exprs =
    let
        alphabet =
            [ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]

        romanNumerals =
            [ "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii", "xiii", "xiv", "xv", "xvi", "xvii", "xviii", "xix", "xx", "xi", "xxii", "xxiii", "xxiv", "xxv", "vi" ]

        alpha k =
            List.Extra.getAt (modBy 26 (k - 1)) alphabet |> Maybe.withDefault "a"

        roman k =
            List.Extra.getAt (modBy 26 (k - 1)) romanNumerals |> Maybe.withDefault "i"

        index_ =
            Dict.get id acc.numberedItemDict |> Maybe.map .index |> Maybe.withDefault 1

        level =
            Dict.get id acc.numberedItemDict |> Maybe.map .level |> Maybe.withDefault 0

        label =
            case modBy 3 level of
                1 ->
                    alpha index_

                2 ->
                    roman index_

                _ ->
                    String.fromInt index_
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


index _ acc _ _ _ _ =
    let
        termList =
            acc.terms
                |> Dict.toList
                |> List.sortBy (\( name, _ ) -> name)
    in
    -- Element.column [ Element.spacing 6 ] (Element.el [ Font.bold ] (Element.text "Index") :: List.map indexItem termList)
    Element.column [ Element.spacing 6 ] (List.map indexItem termList)


indexItem : ( String, { begin : Int, end : Int, id : String } ) -> Element MarkupMsg
indexItem ( name, loc ) =
    Element.link [ Font.color (Element.rgb 0 0 0.8), Events.onClick (SelectId loc.id) ]
        { url = Render.Utility.internalLink loc.id, label = Element.el [] (Element.text (String.toLower name)) }
