module Render.Elm exposing (render)

import Compiler.ASTTools as ASTTools
import Compiler.Acc exposing (Accumulator)
import Dict exposing (Dict)
import Element exposing (Element, alignLeft, alignRight, centerX, column, el, newTabLink, px, spacing)
import Element.Background as Background
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import List.Extra
import Maybe.Extra
import Parser.Expr exposing (Expr(..))
import Parser.MathMacro
import Render.Math
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings exposing (Settings)
import Render.Utility as Utility


render : Int -> Accumulator -> Settings -> Expr -> Element MarkupMsg
render generation acc settings expr =
    case expr of
        Text string meta ->
            Element.el [ Events.onClick (SendMeta meta), htmlId meta.id ] (Element.text string)

        Expr name exprList meta ->
            Element.el [ htmlId meta.id ] (renderMarked name generation acc settings exprList)

        Verbatim name str meta ->
            renderVerbatim name generation acc settings meta str


renderVerbatim name generation acc settings meta str =
    case Dict.get name verbatimDict of
        Nothing ->
            errorText 1 name

        Just f ->
            f generation acc settings meta str


renderMarked name generation acc settings exprList =
    case Dict.get name markupDict of
        Nothing ->
            Element.paragraph [ spacing 8 ] (Element.el [ Background.color errorBackgroundColor, Element.paddingXY 4 2 ] (Element.text name) :: List.map (render generation acc settings) exprList)

        Just f ->
            f generation acc settings exprList


errorBackgroundColor =
    Element.rgb 1 0.8 0.8



-- DICTIONARIES


markupDict : Dict String (Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg)
markupDict =
    Dict.fromList
        [ ( "bibitem", \g acc s exprList -> bibitem g acc s exprList )

        -- STYLE
        , ( "strong", \g acc s exprList -> strong g acc s exprList )
        , ( "bold", \g acc s exprList -> strong g acc s exprList )
        , ( "b", \g acc s exprList -> strong g acc s exprList )
        , ( "italic", \g acc s exprList -> italic g acc s exprList )
        , ( "i", \g acc s exprList -> italic g acc s exprList )
        , ( "boldItalic", \g acc s exprList -> boldItalic g acc s exprList )
        , ( "strike", \g acc s exprList -> strike g acc s exprList )
        , ( "ref", \g acc s exprList -> ref g acc s exprList )
        , ( "reflink", \g acc s exprList -> reflink g acc s exprList )
        , ( "eqref", \g acc s exprList -> eqref g acc s exprList )
        , ( "underline", \g acc s exprList -> underline g acc s exprList )
        , ( "comment", \_ _ _ _ -> Element.none )

        -- LATEX
        , ( "title", \g acc s exprList -> title g acc s exprList )
        , ( "setcounter", \_ _ _ _ -> Element.none )

        -- COLOR
        , ( "red", \g acc s exprList -> red g acc s exprList )
        , ( "blue", \g acc s exprList -> blue g acc s exprList )
        , ( "green", \g acc s exprList -> green g acc s exprList )
        , ( "pink", \g acc s exprList -> pink g acc s exprList )
        , ( "magenta", \g acc s exprList -> magenta g acc s exprList )
        , ( "violet", \g acc s exprList -> violet g acc s exprList )
        , ( "highlight", \g acc s exprList -> highlight g acc s exprList )
        , ( "gray", \g acc s exprList -> gray g acc s exprList )
        , ( "errorHighlight", \g acc s exprList -> errorHighlight g acc s exprList )

        --
        , ( "skip", \g acc s exprList -> skip g acc s exprList )
        , ( "link", \g acc s exprList -> link g acc s exprList )
        , ( "href", \g acc s exprList -> href g acc s exprList )
        , ( "ilink", \g acc s exprList -> ilink g acc s exprList )
        , ( "ulink", \g acc s exprList -> ulink g acc s exprList )
        , ( "abstract", \g acc s exprList -> abstract g acc s exprList )
        , ( "large", \g acc s exprList -> large g acc s exprList )
        , ( "mdash", \_ _ _ _ -> Element.el [] (Element.text "—") )
        , ( "ndash", \_ _ _ _ -> Element.el [] (Element.text "–") )
        , ( "label", \_ _ _ _ -> Element.none )
        , ( "cite", \g acc s exprList -> cite g acc s exprList )
        , ( "table", \g acc s exprList -> table g acc s exprList )
        , ( "image", \g acc s exprList -> image g acc s exprList )
        , ( "tags", invisible )
        , ( "vskip", vskip )
        , ( "syspar", syspar )

        -- MiniLaTeX stuff
        , ( "term", \g acc s exprList -> term g acc s exprList )
        , ( "term_", \g acc s exprList -> Element.none )
        , ( "emph", \g acc s exprList -> emph g acc s exprList )
        , ( "group", \g acc s exprList -> identityFunction g acc s exprList )

        --
        , ( "dollarSign", \_ _ _ _ -> Element.el [] (Element.text "$") )
        , ( "dollar", \_ _ _ _ -> Element.el [] (Element.text "$") )
        , ( "brackets", \g acc s exprList -> brackets g acc s exprList )
        , ( "rb", \g acc s exprList -> rightBracket g acc s exprList )
        , ( "lb", \g acc s exprList -> leftBracket g acc s exprList )
        , ( "bt", \g acc s exprList -> backTick g acc s exprList )
        , ( "ds", \_ _ _ _ -> Element.el [] (Element.text "$") )
        , ( "bs", \g acc s exprList -> Element.paragraph [] (Element.text "\\" :: List.map (render g acc s) exprList) )
        , ( "texarg", \g acc s exprList -> Element.paragraph [] ((Element.text "{" :: List.map (render g acc s) exprList) ++ [ Element.text " }" ]) )
        , ( "backTick", \_ _ _ _ -> Element.el [] (Element.text "`") )
        ]


verbatimDict =
    Dict.fromList
        [ ( "$", \g a s m str -> math g a s m str )
        , ( "`", \g _ s m str -> code g s m str )
        , ( "code", \g _ s m str -> code g s m str )
        , ( "math", \g a s m str -> math g a s m str )
        ]



-- FUNCTIONS


identityFunction g acc s exprList =
    Element.paragraph [] (List.map (render g acc s) exprList)


abstract g acc s exprList =
    Element.paragraph [] [ Element.el [ Font.size 18 ] (Element.text "Abstract."), simpleElement [] g acc s exprList ]


large : Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
large g acc s exprList =
    simpleElement [ Font.size 18 ] g acc s exprList


link : Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
link _ _ _ exprList =
    case List.head <| ASTTools.exprListToStringList exprList of
        Nothing ->
            errorText_ "Please provide label and url"

        Just argString ->
            let
                args =
                    String.words argString

                n =
                    List.length args

                label =
                    List.take (n - 1) args |> String.join " "

                url =
                    List.drop (n - 1) args |> String.join " "
            in
            newTabLink []
                { url = url
                , label = el [ Font.color linkColor ] (Element.text label)
                }


href : Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
href _ _ _ exprList =
    let
        url =
            List.Extra.getAt 0 exprList |> Maybe.andThen ASTTools.getText |> Maybe.withDefault ""

        label =
            List.Extra.getAt 1 exprList |> Maybe.andThen ASTTools.getText |> Maybe.withDefault ""
    in
    newTabLink []
        { url = url
        , label = el [ Font.color linkColor ] (Element.text label)
        }


ilink _ _ _ exprList =
    case List.head <| ASTTools.exprListToStringList exprList of
        Nothing ->
            errorText_ "Please provide label and url"

        Just argString ->
            let
                args =
                    String.words argString

                n =
                    List.length args

                label =
                    List.take (n - 1) args |> String.join " "

                docId =
                    List.drop (n - 1) args |> String.join " "
            in
            Input.button []
                { onPress = Just (GetPublicDocument docId)
                , label = Element.el [ Element.centerX, Element.centerY, Font.size 14, Font.color (Element.rgb 0 0 0.8) ] (Element.text label)
                }


ulink _ _ _ exprList =
    case List.head <| ASTTools.exprListToStringList exprList of
        Nothing ->
            errorText_ "Please provide label and url"

        Just argString ->
            let
                args =
                    String.words argString

                n =
                    List.length args

                label =
                    List.take (n - 1) args |> String.join " "

                fragment =
                    List.drop (n - 1) args |> String.join " "

                username =
                    String.split ":" fragment |> List.head |> Maybe.withDefault "---"
            in
            Input.button []
                { onPress = Just (GetPublicDocumentFromAuthor username fragment)
                , label = Element.el [ Element.centerX, Element.centerY, Font.size 14, Font.color (Element.rgb 0 0 0.8) ] (Element.text label)
                }


image generation acc settings body =
    let
        arguments : List String
        arguments =
            ASTTools.exprListToStringList body |> List.map String.words |> List.concat

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
            Utility.keyValueDict keyValueStrings

        --  |> Dict.insert "caption" (Maybe.andThen ASTTools.getText captionExpr |> Maybe.withDefault "")
        description =
            Dict.get "caption" dict |> Maybe.withDefault ""

        caption =
            if captionPhrase == "" then
                Element.none

            else
                Element.row [ placement, Element.width Element.fill ] [ el [ Element.width Element.fill ] (Element.text captionPhrase) ]

        width =
            case Dict.get "width" dict of
                Nothing ->
                    px displayWidth

                Just w_ ->
                    case String.toInt w_ of
                        Nothing ->
                            px displayWidth

                        Just w ->
                            px w

        placement =
            case Dict.get "placement" dict of
                Nothing ->
                    centerX

                Just "left" ->
                    alignLeft

                Just "right" ->
                    alignRight

                Just "center" ->
                    centerX

                _ ->
                    centerX

        displayWidth =
            settings.width
    in
    column [ spacing 8, Element.width (px settings.width), placement, Element.paddingXY 0 18 ]
        [ Element.image [ Element.width width, placement ]
            { src = url, description = description }
        , el [ placement ] caption
        ]


bibitem : Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
bibitem generation acc settings str =
    Element.paragraph [ Element.width Element.fill ] [ Element.text (ASTTools.exprListToStringList str |> String.join " " |> (\s -> "[" ++ s ++ "]")) ]


cite : Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
cite generation acc settings str =
    let
        tag : String
        tag =
            ASTTools.exprListToStringList str |> String.join ""

        id =
            Dict.get tag acc.reference |> Maybe.map .id |> Maybe.withDefault ""
    in
    Element.paragraph
        [ Element.width Element.fill
        , Events.onClick (SendId id)
        , Events.onClick (SelectId id)
        , Font.color (Element.rgb 0.2 0.2 1.0)
        ]
        [ Element.text (tag |> (\s -> "[" ++ s ++ "]")) ]


code g s m str =
    verbatimElement codeStyle g s m str


math g a s m str =
    mathElement g a s m str


table : Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
table g acc s rows =
    Element.column [ Element.spacing 8 ] (List.map (tableRow g acc s) rows)


tableRow : Int -> Accumulator -> Settings -> Expr -> Element MarkupMsg
tableRow g acc s expr =
    case expr of
        Expr "tableRow" items _ ->
            Element.row [ spacing 8 ] (List.map (tableItem g acc s) items)

        _ ->
            Element.none


tableItem : Int -> Accumulator -> Settings -> Expr -> Element MarkupMsg
tableItem g acc s expr =
    case expr of
        Expr "tableItem" exprList _ ->
            Element.paragraph [ Element.width (Element.px 100) ] (List.map (render g acc s) exprList)

        _ ->
            Element.none


skip g acc s exprList =
    let
        numVal : String -> Int
        numVal str =
            String.toInt str |> Maybe.withDefault 0

        f : String -> Element MarkupMsg
        f str =
            column [ Element.spacingXY 0 (numVal str) ] [ Element.text "" ]
    in
    f1 f g acc s exprList


vskip _ _ _ exprList =
    let
        h =
            ASTTools.exprListToStringList exprList |> String.join "" |> String.toInt |> Maybe.withDefault 0
    in
    -- Element.column [ Element.paddingXY 0 100 ] (Element.text "-")
    Element.column [ Element.height (Element.px h) ] [ Element.text "" ]


syspar _ _ _ _ =
    Element.column [ Element.height (Element.px 10) ] [ Element.text "" ]


strong g acc s exprList =
    simpleElement [ Font.bold ] g acc s exprList


brackets g acc s exprList =
    Element.paragraph [ Element.spacing 8 ] [ Element.text "[", simpleElement [] g acc s exprList, Element.text " ]" ]


rightBracket g acc s exprList =
    Element.text "]"


leftBracket g acc s exprList =
    Element.text "["


backTick g acc s exprList =
    Element.text "`"


italic g acc s exprList =
    simpleElement [ Font.italic, Element.paddingEach { left = 0, right = 2, top = 0, bottom = 0 } ] g acc s exprList


boldItalic g acc s exprList =
    simpleElement [ Font.italic, Font.bold, Element.paddingEach { left = 0, right = 2, top = 0, bottom = 0 } ] g acc s exprList


title g acc s exprList =
    simpleElement [ Font.size 36, Element.paddingEach { left = 0, right = 2, top = 0, bottom = 0 } ] g acc s exprList


term g acc s exprList =
    simpleElement [ Font.italic, Element.paddingEach { left = 0, right = 2, top = 0, bottom = 0 } ] g acc s exprList


emph g acc s exprList =
    simpleElement [ Font.italic, Element.paddingEach { left = 0, right = 2, top = 0, bottom = 0 } ] g acc s exprList



-- COLOR FUNCTIONS


gray g acc s exprList =
    simpleElement [ Font.color (Element.rgb 0.5 0.5 0.5) ] g acc s exprList


red g acc s exprList =
    simpleElement [ Font.color (Element.rgb255 200 0 0) ] g acc s exprList


blue g acc s exprList =
    simpleElement [ Font.color (Element.rgb255 0 0 200) ] g acc s exprList


green g acc s exprList =
    simpleElement [ Font.color (Element.rgb255 0 140 0) ] g acc s exprList


magenta g acc s exprList =
    simpleElement [ Font.color (Element.rgb255 255 51 192) ] g acc s exprList


pink g acc s exprList =
    simpleElement [ Font.color (Element.rgb255 255 100 100) ] g acc s exprList


violet g acc s exprList =
    simpleElement [ Font.color (Element.rgb255 150 100 255) ] g acc s exprList


highlight g acc s exprList_ =
    let
        colorName =
            ASTTools.filterExpressionsOnName "color" exprList_
                |> List.head
                |> Maybe.andThen ASTTools.getText
                |> Maybe.withDefault "yellow"
                |> String.trim

        exprList =
            ASTTools.filterOutExpressionsOnName "color" exprList_

        colorElement =
            Dict.get colorName colorDict |> Maybe.withDefault (Element.rgb255 255 255 0)
    in
    simpleElement [ Background.color colorElement, Element.paddingXY 6 3 ] g acc s exprList


colorDict : Dict String Element.Color
colorDict =
    Dict.fromList
        [ ( "yellow", Element.rgb255 255 255 0 )
        , ( "blue", Element.rgb255 180 180 255 )
        ]


ref : Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
ref g acc s exprList =
    let
        key =
            List.map ASTTools.getText exprList |> Maybe.Extra.values |> String.join "" |> String.trim

        ref_ =
            Dict.get key acc.reference

        val =
            ref_ |> Maybe.map .numRef |> Maybe.withDefault ""

        id =
            ref_ |> Maybe.map .id |> Maybe.withDefault ""
    in
    -- Element.el [ Font.color (Element.rgb 0 0 0.7) ] (Element.text val)
    Element.link
        [ Font.color (Element.rgb 0 0 0.7)
        , Font.bold
        , Events.onClick (SelectId id)
        ]
        { url = Utility.internalLink id
        , label = Element.paragraph [] [ Element.text val ]
        }


{-|

    \reflink{LINK_TEXT LABEL}

-}
reflink : Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
reflink g acc s exprList =
    let
        argString =
            List.map ASTTools.getText exprList |> Maybe.Extra.values |> String.join " "

        args =
            String.words argString

        n =
            List.length args

        key =
            List.drop (n - 1) args |> String.join ""

        label =
            List.take (n - 1) args |> String.join " "

        ref_ =
            Dict.get key acc.reference

        id =
            ref_ |> Maybe.map .id |> Maybe.withDefault ""
    in
    Element.link
        [ Font.color (Element.rgb 0 0 0.7)
        , Events.onClick (SendId id)
        , Events.onClick (SelectId id)
        ]
        { url = Utility.internalLink id
        , label = Element.paragraph [] [ Element.text label ]
        }


eqref : Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
eqref g acc s exprList =
    let
        key =
            List.map ASTTools.getText exprList |> Maybe.Extra.values |> String.join "" |> String.trim

        ref_ =
            Dict.get key acc.reference

        val =
            ref_ |> Maybe.map .numRef |> Maybe.withDefault ""

        id =
            ref_ |> Maybe.map .id |> Maybe.withDefault ""
    in
    Element.link
        [ Font.color (Element.rgb 0 0 0.7)
        , Events.onClick (SelectId id)
        ]
        { url = Utility.internalLink id
        , label = Element.paragraph [] [ Element.text ("(" ++ val ++ ")") ]
        }



-- FONT STYLE FUNCTIONS


strike g acc s exprList =
    simpleElement [ Font.strike ] g acc s exprList


underline g acc s exprList =
    simpleElement [ Font.underline ] g acc s exprList


errorHighlight g acc s exprList =
    simpleElement [ Background.color (Element.rgb255 255 200 200), Element.paddingXY 4 2 ] g acc s exprList



-- HELPERS


simpleElement : List (Element.Attribute MarkupMsg) -> Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
simpleElement formatList g acc s exprList =
    Element.paragraph formatList (List.map (render g acc s) exprList)


{-| For one-element functions
-}
f1 : (String -> Element MarkupMsg) -> Int -> Accumulator -> Settings -> List Expr -> Element MarkupMsg
f1 f g acc s exprList =
    case ASTTools.exprListToStringList exprList of
        -- TODO: temporary fix: parse is producing the args in reverse order
        arg1 :: _ ->
            f arg1

        _ ->
            el [ Font.color errorColor ] (Element.text "Invalid arguments")


verbatimElement formatList g s meta str =
    Element.el (htmlId meta.id :: formatList) (Element.text str)


htmlId str =
    Element.htmlAttribute (Html.Attributes.id str)


errorText index str =
    Element.el [ Font.color (Element.rgb255 200 40 40) ] (Element.text <| "(" ++ String.fromInt index ++ ") not implemented: " ++ str)


errorText_ str =
    Element.el [ Font.color (Element.rgb255 200 40 40) ] (Element.text str)


invisible g acc s exprList =
    Element.none


mathElement generation acc settings meta str =
    -- "width" is not used for inline math, but some string needs to be there
    Render.Math.mathText generation "width" meta.id Render.Math.InlineMathMode (Parser.MathMacro.evalStr acc.mathMacroDict str)



-- DEFINITIONS


codeStyle =
    [ Font.family
        [ Font.typeface "Inconsolata"
        , Font.monospace
        ]
    , Font.unitalicized
    , Font.color Render.Settings.codeColor
    , Element.paddingEach { left = 2, right = 2, top = 0, bottom = 0 }
    ]


errorColor =
    Element.rgb 0.8 0 0


linkColor =
    Element.rgb 0 0 0.8
