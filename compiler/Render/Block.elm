module Render.Block exposing (render)

import Chart
import Chart.Attributes
import Compiler.ASTTools as ASTTools
import Compiler.Acc exposing (Accumulator)
import Config
import Dict exposing (Dict)
import Either exposing (Either(..))
import Element exposing (Element)
import Element.Background as Background
import Element.Events as Events
import Element.Font as Font
import Element.Input
import Html.Attributes
import List.Extra
import Maybe.Extra
import Parser.Block exposing (BlockType(..), ExpressionBlock(..))
import Parser.Expr exposing (Expr)
import Parser.MathMacro
import Render.Color as Color
import Render.Elm
import Render.Math exposing (DisplayMode(..))
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings exposing (Settings)
import Render.Utility
import String.Extra
import SvgParser
import View.Color


htmlId str =
    Element.htmlAttribute (Html.Attributes.id str)



-- SETTINGS


render : Int -> Accumulator -> Settings -> ExpressionBlock -> Element MarkupMsg
render count acc settings (ExpressionBlock { name, args, blockType, content, id, sourceText }) =
    case blockType of
        Paragraph ->
            case content of
                Right exprs ->
                    let
                        color =
                            if id == settings.selectedId then
                                Background.color (Element.rgb 0.9 0.9 1.0)

                            else
                                Background.color settings.backgroundColor
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
        , ( "quotation", quotation )
        , ( "q", question )
        , ( "a", answer )
        , ( "document", document )
        , ( "collection", collection )
        , ( "bibitem", bibitem )

        -- , ( "heading", section )
        , ( "section", section )
        , ( "title", \_ _ _ _ _ _ -> Element.none )
        , ( "subtitle", \_ _ _ _ _ _ -> Element.none )
        , ( "author", \_ _ _ _ _ _ -> Element.none )
        , ( "date", \_ _ _ _ _ _ -> Element.none )
        , ( "textmacros", \_ _ _ _ _ _ -> Element.none )
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
        , ( "equation", renderEquation )
        , ( "aligned", aligned )
        , ( "code", renderCode )
        , ( "verse", renderVerse )
        , ( "verbatim", renderVerbatim )
        , ( "comment", renderComment )
        , ( "mathmacros", renderComment )
        , ( "datatable", datatable )
        , ( "lineChart", lineChart )
        , ( "svg", svg )
        , ( "quiver", quiver )
        , ( "load-files", \_ _ _ _ _ _ -> Element.none )
        , ( "include", \_ _ _ _ _ _ -> Element.none )
        ]


renderComment : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderComment _ _ _ _ _ _ =
    Element.none


csvTo2DData : String -> List { x : Float, y : Float }
csvTo2DData str =
    str
        |> String.lines
        |> List.filter (\line -> String.trim line /= "" && String.left 1 line /= "#")
        |> List.map (String.split "," >> listTo2DPoint)
        |> Maybe.Extra.values


listTo2DPoint : List String -> Maybe { x : Float, y : Float }
listTo2DPoint list =
    case list of
        x :: y :: rest ->
            ( String.toFloat (String.trim x), String.toFloat (String.trim y) ) |> valueOfPair |> Maybe.map (\( u, v ) -> { x = u, y = v })

        _ ->
            Nothing


valueOfPair : ( Maybe a, Maybe b ) -> Maybe ( a, b )
valueOfPair ( ma, mb ) =
    case ( ma, mb ) of
        ( Nothing, Nothing ) ->
            Nothing

        ( Just a, Nothing ) ->
            Nothing

        ( Nothing, Just b ) ->
            Nothing

        ( Just a, Just b ) ->
            Just ( a, b )


lineChart : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
lineChart count acc settings args id str =
    let
        data =
            csvTo2DData str
    in
    Element.el [ Element.width (Element.px settings.width), Element.paddingEach { left = 48, right = 0, top = 36, bottom = 36 } ]
        (rawLineChart data)


rawLineChart : List { a | x : Float, y : Float } -> Element msg
rawLineChart data =
    Chart.chart
        [ Chart.Attributes.height 200
        , Chart.Attributes.width 400
        ]
        [ Chart.xLabels [ Chart.Attributes.fontSize 10 ]
        , Chart.yLabels [ Chart.Attributes.withGrid, Chart.Attributes.fontSize 10 ]
        , Chart.series .x
            [ Chart.interpolated .y [ Chart.Attributes.color Chart.Attributes.red ] []
            ]
            data
        ]
        |> Element.html


svg : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
svg count acc settings args id str =
    case SvgParser.parse str of
        Ok html_ ->
            Element.column
                [ Element.paddingEach { left = 0, right = 0, top = 24, bottom = 0 }
                , Element.width (Element.px settings.width)
                ]
                [ Element.column [ Element.centerX ] [ html_ |> Element.html ]
                ]

        Err _ ->
            Element.el [] (Element.text "SVG parse error")


{-| Create elements from HTML markup. On parsing error, output no elements.
-}



--withNodes : String -> List (HStyled.Html msg)
--withNodes s =
--    case HP.run s of
--        Ok parsedNodes ->
--            List.map HStyled.fromUnstyled (HPU.toVirtualDom parsedNodes)
--
--        _ ->
--            [ HStyled.fromUnstyled (text "Parsing error") ]
--


quiver : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
quiver count acc settings args id str =
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
            Element.el [ Font.size 16, Font.color View.Color.red ] (Element.text "Something is wrong")

        Just ( imageData, latexData ) ->
            let
                arguments : List String
                arguments =
                    String.words imageData

                url =
                    List.head arguments |> Maybe.withDefault "no-image"

                remainingArguments =
                    List.drop 1 arguments

                keyValueStrings_ =
                    List.filter (\s -> String.contains ":" s) remainingArguments

                keyValueStrings : List String
                keyValueStrings =
                    List.filter (\s -> not (String.contains "caption" s)) keyValueStrings_

                captionLeadString =
                    List.filter (\s -> String.contains "caption" s) keyValueStrings_
                        |> String.join ""
                        |> String.replace "caption:" ""

                captionPhrase =
                    (captionLeadString :: List.filter (\s -> not (String.contains ":" s)) remainingArguments) |> String.join " "

                dict =
                    Render.Utility.keyValueDict keyValueStrings

                --  |> Dict.insert "caption" (Maybe.andThen ASTTools.getText captionExpr |> Maybe.withDefault "")
                description =
                    Dict.get "caption" dict |> Maybe.withDefault ""

                caption =
                    if captionPhrase == "" then
                        Element.none

                    else
                        Element.row [ placement, Element.width Element.fill ] [ Element.el [ Element.width Element.fill ] (Element.text captionPhrase) ]

                width =
                    case Dict.get "width" dict of
                        Nothing ->
                            Element.px displayWidth

                        Just w_ ->
                            case String.toInt w_ of
                                Nothing ->
                                    Element.px displayWidth

                                Just w ->
                                    Element.px w

                placement =
                    case Dict.get "placement" dict of
                        Nothing ->
                            Element.centerX

                        Just "left" ->
                            Element.alignLeft

                        Just "right" ->
                            Element.alignRight

                        Just "center" ->
                            Element.centerX

                        _ ->
                            Element.centerX

                displayWidth =
                    settings.width
            in
            Element.column [ Element.spacing 8, Element.width (Element.px settings.width), placement, Element.paddingXY 0 18 ]
                [ Element.image [ Element.width width, placement ]
                    { src = url, description = description }
                , Element.el [ placement ] caption
                ]



{-

   % https://q.uiver.app/?q=WzAsNCxbMCwzLCJBIl0sWzIsMywiQiJdLFsxLDIsIlUiXSxbMSwwLCJYIl0sWzIsMCwicCIsMV0sWzIsMSwicSIsMV0sWzMsMCwiZiIsMSx7ImN1cnZlIjoyfV0sWzMsMSwiZyIsMSx7ImN1cnZlIjotMn1dLFszLDIsIm0iLDFdXQ==
   \[\begin{tikzcd}
   & X \\
   \\
   & U \\
   A && B
   \arrow["p"{description}, from=3-2, to=4-1]
   \arrow["q"{description}, from=3-2, to=4-3]
   \arrow["f"{description}, curve={height=12pt}, from=1-2, to=4-1]
   \arrow["g"{description}, curve={height=-12pt}, from=1-2, to=4-3]
   \arrow["m"{description}, from=1-2, to=3-2]
   \end{tikzcd}\]

-}


datatable : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
datatable count acc settings args id str =
    let
        argString =
            String.join " " args

        newArgs =
            argString |> String.split ";" |> List.map String.trim

        argDict =
            Render.Utility.keyValueDict newArgs

        title =
            case Dict.get "title" argDict of
                Nothing ->
                    Element.none

                Just title_ ->
                    Element.el [ Font.bold ] (Element.text title_)

        columnsToDisplay : List Int
        columnsToDisplay =
            Dict.get "columns" argDict
                |> Maybe.map (String.split ",")
                |> Maybe.withDefault []
                |> List.map (String.trim >> String.toInt)
                |> Maybe.Extra.values
                |> List.map (\n -> n - 1)

        lines =
            String.split "\n" str

        rawCells : List (List String)
        rawCells =
            List.map (String.split ",") lines
                |> List.map (List.map String.trim)

        selectedCells : List (List String)
        selectedCells =
            if columnsToDisplay == [] then
                rawCells

            else
                let
                    cols : List ( Int, List String )
                    cols =
                        List.Extra.transpose rawCells |> List.indexedMap (\k col -> ( k, col ))

                    updater : ( Int, List String ) -> List (List String) -> List (List String)
                    updater =
                        \( k, col ) acc_ ->
                            if List.member k columnsToDisplay then
                                col :: acc_

                            else
                                acc_

                    selectedCols =
                        List.foldl updater [] cols
                in
                List.Extra.transpose (List.reverse selectedCols)

        columnWidths : List Int
        columnWidths =
            List.map (List.map String.length) selectedCells
                |> List.Extra.transpose
                |> List.map (\column -> List.maximum column |> Maybe.withDefault 1)
                |> List.map (\w -> Config.fontWidth * w)

        renderRow : List Int -> List String -> Element MarkupMsg
        renderRow widths_ cells_ =
            let
                totalWidth =
                    List.sum widths_ + 0
            in
            Element.row [ Element.width (Element.px totalWidth) ] (List.map2 (\cell width -> Element.el [ Element.width (Element.px width) ] (Element.text cell)) cells_ widths_)
    in
    Element.column [ Element.spacing 12, Element.paddingEach { left = 36, right = 0, top = 18, bottom = 18 } ] (title :: List.map (renderRow columnWidths) selectedCells)


aligned : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
aligned count acc settings args id str =
    Element.row [ Element.width (Element.px settings.width), Render.Utility.elementAttribute "id" id ]
        [ Element.el [ Element.centerX ] (aligned_ count acc settings args id str)
        , Element.el [ Element.alignRight, Font.size 12, equationLabelPadding ] (Element.text <| "(" ++ Render.Utility.getArg "??(11)" 0 args ++ ")")
        ]


equationLabelPadding =
    Element.paddingEach { left = 0, right = 18, top = 0, bottom = 0 }


section count acc settings args id exprs =
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
         , Events.onClick (SendId "title")
         , Element.paddingEach { top = 20, bottom = 0, left = 0, right = 0 }
         ]
            ++ highlightAttrs id settings
        )
        { url = Render.Utility.internalLink (settings.titlePrefix ++ "title"), label = Element.paragraph [] (sectionNumber :: renderWithDefault "| section" count acc settings exprs) }


renderWithDefault : String -> Int -> Accumulator -> Settings -> List Expr -> List (Element MarkupMsg)
renderWithDefault default count acc settings exprs =
    if List.isEmpty exprs then
        [ Element.el [ Font.color Render.Settings.redColor, Font.size 14 ] (Element.text default) ]

    else
        List.map (Render.Elm.render count acc settings) exprs


renderWithDefault2 : String -> Int -> Accumulator -> Settings -> List Expr -> List (Element MarkupMsg)
renderWithDefault2 default count acc settings exprs =
    List.map (Render.Elm.render count acc settings) exprs


indented count acc settings _ id exprs =
    Element.paragraph ([ Render.Settings.leftIndentation, Events.onClick (SendId id), Render.Utility.elementAttribute "id" id ] ++ highlightAttrs id settings)
        (renderWithDefault "| indent" count acc settings exprs)


quotation count acc settings args id exprs =
    let
        attribution_ =
            String.join " " args

        attribution =
            if attribution_ == "" then
                ""

            else
                "—" ++ attribution_
    in
    Element.column [ Element.spacing 12 ]
        [ Element.paragraph ([ Font.italic, Render.Settings.leftIndentation, Events.onClick (SendId id), Render.Utility.elementAttribute "id" id ] ++ highlightAttrs id settings)
            (renderWithDefault "| indent" count acc settings exprs)
        , Element.el [ Render.Settings.wideLeftIndentation, Font.italic ] (Element.text attribution)
        ]


question count acc settings args id exprs =
    let
        title =
            String.join " " (List.drop 1 args)

        label =
            List.take 1 args |> String.join ""
    in
    Element.column [ Element.spacing 12 ]
        [ Element.el [ Font.bold ] (Element.text (title ++ " " ++ label))
        , Element.paragraph ([ Font.italic, Events.onClick (SendId id), Render.Utility.elementAttribute "id" id ] ++ highlightAttrs id settings)
            (renderWithDefault "..." count acc settings exprs)
        ]


answer count acc settings args id exprs =
    let
        title =
            String.join " " (List.drop 1 args)

        clicker =
            if settings.selectedId == id then
                Events.onClick (ProposeSolution Render.Msg.Unsolved)

            else
                Events.onClick (ProposeSolution (Render.Msg.Solved id))
    in
    Element.column [ Element.spacing 12, Element.paddingEach { top = 0, bottom = 24, left = 0, right = 0 } ]
        [ Element.el [ Font.bold, Font.color Color.blue, clicker ] (Element.text title)
        , if settings.selectedId == id then
            Element.el [ Events.onClick (ProposeSolution Render.Msg.Unsolved) ]
                (Element.paragraph ([ Font.italic, Render.Utility.elementAttribute "id" id, Element.paddingXY 8 8 ] ++ highlightAttrs id settings)
                    (renderWithDefault "..." count acc settings exprs)
                )

          else
            Element.none
        ]


bibitem : Int -> Accumulator -> Settings -> List String -> String -> List Expr -> Element MarkupMsg
bibitem count acc settings args id exprs =
    let
        label =
            List.Extra.getAt 0 args |> Maybe.withDefault "(12)" |> (\s -> "[" ++ s ++ "]")
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


collection count acc settings args id exprs =
    --Element.el [ Font.bold ] (Element.text "Contents")
    Element.none


document count acc settings args selectedId exprs =
    let
        docId =
            List.Extra.getAt 0 args |> Maybe.withDefault "--"

        level =
            List.Extra.getAt 1 args |> Maybe.withDefault "1" |> String.toInt |> Maybe.withDefault 1

        title =
            List.map ASTTools.getText exprs |> Maybe.Extra.values |> String.join " " |> truncateString 35

        sectionNumber =
            case List.Extra.getAt 2 args of
                Just "-" ->
                    "- "

                Just s ->
                    s ++ ". "

                Nothing ->
                    "- "
    in
    Element.row
        [ Element.alignTop
        , Render.Utility.elementAttribute "id" selectedId
        , vspace 0 Render.Settings.topMarginForChildren
        , Element.moveRight (15 * (level - 1) |> toFloat)
        , fontColor settings.selectedId settings.selectedSlug docId
        ]
        [ Element.el
            [ Font.size 14
            , Element.alignTop
            , Element.width (Element.px 30)
            ]
            (Element.text sectionNumber)
        , ilink title settings.selectedId settings.selectedSlug docId

        -- ilink docTitle selectedId selecteSlug docId
        ]


truncateString : Int -> String -> String
truncateString k str =
    let
        str2 =
            truncateString_ k str
    in
    if str == str2 then
        str

    else
        str2 ++ " ..."


truncateString_ : Int -> String -> String
truncateString_ k str =
    if String.length str < k then
        str

    else
        let
            words =
                String.words str

            n =
                List.length words
        in
        words
            |> List.take (n - 1)
            |> String.join " "
            |> truncateString_ k


fontColor selectedId selectedSlug docId =
    if selectedId == docId then
        Font.color (Element.rgb 0.8 0 0)

    else if selectedSlug == Just docId then
        Font.color (Element.rgb 0.8 0 0)

    else
        Font.color (Element.rgb 0 0 0.9)


ilink : String -> String -> Maybe String -> String -> Element MarkupMsg
ilink docTitle selectedId selecteSlug docId =
    Element.Input.button []
        { onPress = Just (GetPublicDocument Render.Msg.MHStandard docId)

        -- { onPress = Just (GetDocumentById docId)
        , label =
            Element.el
                [ Element.centerX
                , Element.centerY
                , Font.size 14
                , fontColor selectedId selecteSlug docId
                ]
                (Element.text docTitle)
        }


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
            (renderWithDefault2 ("| " ++ name) count acc settings exprs)
        ]


renderDisplayMath_ : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderDisplayMath_ count acc settings _ id str =
    let
        w =
            String.fromInt settings.width ++ "px"

        filteredLines =
            -- lines of math text to be rendered: filter stuff out
            String.lines str
                |> List.filter (\line -> not (String.left 2 line == "$$"))
                |> List.filter (\line -> not (String.left 6 line == "[label"))
                |> List.filter (\line -> line /= "")

        adjustedLines =
            List.map (Parser.MathMacro.evalStr acc.mathMacroDict) filteredLines
                |> List.filter (\line -> line /= "")
                |> List.map (\line -> line ++ "\\\\")

        leftPadding =
            Element.paddingEach { left = 45, right = 0, top = 0, bottom = 0 }
    in
    Element.column [ leftPadding ]
        [ Render.Math.mathText count w id DisplayMathMode (adjustedLines |> String.join "\n") ]


renderEquation : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderEquation count acc settings args id str =
    let
        w =
            String.fromInt settings.width ++ "px"

        filteredLines =
            -- lines of math text to be rendered: filter stuff out
            String.lines str
                |> List.filter (\line -> not (String.left 2 line == "$$") && not (String.left 6 line == "[label") && not (line == "end"))

        adjustedLines1 =
            -- TODO: we need a better solution than the below for not messing up
            -- TODO internal \\begin-\\end pairs
            List.map (Parser.MathMacro.evalStr acc.mathMacroDict) filteredLines
                |> List.filter (\line -> line /= "")
                |> List.map
                    (\line ->
                        if String.left 6 line /= "\\begin" then
                            line ++ "\\\\"

                        else
                            line
                    )

        adjustedLines =
            "\\begin{equation}" :: "\\nonumber" :: adjustedLines1 ++ [ "\\end{equation}" ]

        content =
            String.join "\n" adjustedLines

        leftPadding =
            Element.paddingEach { left = 45, right = 0, top = 0, bottom = 0 }

        attrs =
            if id == settings.selectedId then
                [ Events.onClick (SendId id), leftPadding, Background.color (Element.rgb 0.8 0.8 1.0) ]

            else
                [ Events.onClick (SendId id), leftPadding ]

        attrs2 =
            if List.member "highlight" args then
                Background.color (Element.rgb 0.85 0.85 1.0) :: [ Element.centerX ]

            else
                [ Element.centerX ]
    in
    Element.row ([ Element.width (Element.px settings.width), Render.Utility.elementAttribute "id" id ] ++ attrs)
        [ Element.el attrs2 (Render.Math.mathText count w id DisplayMathMode content)
        , Element.el [ Element.alignRight, Font.size 12, equationLabelPadding ] (Element.text <| "(" ++ Render.Utility.getArg "(??)" 0 args ++ ")")
        ]


aligned_ : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
aligned_ count acc settings _ id str =
    let
        w =
            String.fromInt settings.width ++ "px"

        filteredLines =
            -- lines of math text to be rendered: filter stuff out
            String.lines str
                |> List.filter (\line -> not (String.left 6 line == "[label") && not (line == ""))

        leftPadding =
            Element.paddingEach { left = 45, right = 0, top = 0, bottom = 0 }

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
            List.map (deleteTrailingSlashes >> Parser.MathMacro.evalStr acc.mathMacroDict) filteredLines
                |> List.filter (\line -> line /= "")
                |> List.map (\line -> line ++ "\\\\")

        adjustedLines =
            "\\begin{aligned}" :: adjustedLines_ ++ [ "\\end{aligned}" ]

        content =
            String.join "\n" adjustedLines
    in
    Element.column attrs
        [ Render.Math.mathText count w id DisplayMathMode content ]


highlightAttrs id settings =
    if id == settings.selectedId then
        [ Events.onClick (SendId id), Background.color (Element.rgb 0.8 0.8 1.0) ]

    else
        [ Events.onClick (SendId id) ]


renderCode : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderCode _ _ _ _ id str =
    Element.column
        [ Font.color Render.Settings.codeColor
        , Font.family
            [ Font.typeface "Inconsolata"
            , Font.monospace
            ]

        --, Element.spacing 8
        , Element.paddingEach { left = 24, right = 0, top = 0, bottom = 0 }
        , Events.onClick (SendId id)
        , Render.Utility.elementAttribute "id" id
        ]
        (List.map renderVerbatimLine (String.lines (String.trim str)))


renderVerse : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderVerse _ _ _ _ id str =
    Element.column
        [ Events.onClick (SendId id)
        , Render.Utility.elementAttribute "id" id
        ]
        (List.map renderVerbatimLine (String.lines (String.trim str)))


renderVerbatimLine str =
    if String.trim str == "" then
        Element.el [ Element.height (Element.px 11) ] (Element.text "")

    else
        Element.el [ Element.height (Element.px 22) ] (Element.text str)


renderVerbatim : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
renderVerbatim _ _ _ _ id str =
    Element.column
        [ Font.family
            [ Font.typeface "Inconsolata"
            , Font.monospace
            ]
        , Element.spacing 8
        , Element.paddingEach { left = 24, right = 0, top = 0, bottom = 0 }
        , Events.onClick (SendId id)
        , Render.Utility.elementAttribute "id" id
        ]
        (List.map renderVerbatimLine (String.lines (String.trim str)))


item count acc settings args id exprs =
    let
        level =
            Dict.get id acc.numberedItemDict |> Maybe.map .level |> Maybe.withDefault 0

        label =
            case modBy 3 level of
                0 ->
                    String.fromChar '●'

                1 ->
                    String.fromChar '○'

                _ ->
                    "◊"
    in
    Element.row [ Element.moveRight (indentationScale * level |> toFloat), Element.alignTop, Render.Utility.elementAttribute "id" id, vspace 0 Render.Settings.topMarginForChildren ]
        [ Element.el
            [ Font.size 14
            , Element.alignTop
            , Element.moveRight 6
            , Element.width (Element.px 24)
            , Render.Settings.leftIndentation
            ]
            (Element.text label)
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

        val =
            Dict.get id acc.numberedItemDict

        index_ =
            val |> Maybe.map .index |> Maybe.withDefault 1

        level =
            val |> Maybe.map .level |> Maybe.withDefault 0

        label =
            case modBy 3 level of
                1 ->
                    alpha index_

                2 ->
                    roman index_

                _ ->
                    String.fromInt index_
    in
    Element.row [ Element.moveRight (indentationScale * level |> toFloat), Element.alignTop, Render.Utility.elementAttribute "id" id, vspace 0 Render.Settings.topMarginForChildren ]
        [ Element.el
            [ Font.size 14
            , Element.alignTop
            , Element.width (Element.px 24)
            , Render.Settings.leftRightIndentation
            ]
            (Element.text (label ++ ". "))
        , Element.paragraph [ Render.Settings.leftIndentation, Events.onClick (SendId id) ]
            (renderWithDefault "| numbered" count acc settings exprs)
        ]


indentationScale =
    15


index _ acc _ _ _ _ =
    let
        groupItemList : List GroupItem
        groupItemList =
            acc.terms
                |> Dict.toList
                |> List.map (\( name, item_ ) -> ( String.trim name, item_ ))
                |> List.sortBy (\( name, _ ) -> name)
                |> List.Extra.groupWhile (\a b -> String.left 1 (Tuple.first a) == String.left 1 (Tuple.first b))
                |> List.map (\thing -> group thing)
                |> List.concat

        ngroupItemList =
            List.length groupItemList

        groupItemListList : List (List GroupItem)
        groupItemListList =
            groupItemList
                |> List.Extra.greedyGroupsOf 30
                |> List.map normalize
    in
    Element.row [ Element.spacing 18 ] (List.map renderGroup groupItemListList)


renderGroup : List GroupItem -> Element MarkupMsg
renderGroup groupItems =
    Element.column [ Element.alignTop, Element.spacing 6, Element.width (Element.px 150) ] (List.map indexItem groupItems)


normalize gp =
    case List.head gp of
        Just GBlankLine ->
            List.drop 1 gp

        Just (GItem _) ->
            gp

        Nothing ->
            gp


group : ( Item, List Item ) -> List GroupItem
group ( item_, list ) =
    GBlankLine :: GItem item_ :: List.map GItem list


type GroupItem
    = GBlankLine
    | GItem Item


type alias Item =
    ( String, { begin : Int, end : Int, id : String } )


indexItem : GroupItem -> Element MarkupMsg
indexItem groupItem =
    case groupItem of
        GBlankLine ->
            Element.el [ Element.height (Element.px 8) ] (Element.text "")

        GItem item_ ->
            indexItem_ item_


indexItem_ : Item -> Element MarkupMsg
indexItem_ ( name, loc ) =
    Element.link [ Font.color (Element.rgb 0 0 0.8), Events.onClick (SelectId loc.id) ]
        { url = Render.Utility.internalLink loc.id, label = Element.el [] (Element.text (String.toLower name)) }
