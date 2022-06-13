module Render.LineChart exposing (view)

import Chart
import Chart.Attributes
import Compiler.Acc exposing (Accumulator)
import Element exposing (Element)
import Element.Font as Font
import Maybe.Extra
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings exposing (Settings)
import View.Color


type ChartData
    = ChartData2D (List { x : Float, y : Float })
    | ChartData3D (List { x : Float, y : Float, z : Float })
    | ChartData4D (List { x : Float, y : Float, z : Float, w : Float })


csvTo2ChartData : String -> Maybe ChartData
csvTo2ChartData str =
    let
        dataLines : List String
        dataLines =
            str
                |> String.lines
                |> List.filter (\line -> String.trim line /= "" && String.left 1 line /= "#")

        dimension =
            Maybe.map (String.split ",") (List.head dataLines) |> Maybe.map List.length
    in
    case dimension of
        Nothing ->
            Nothing

        Just 2 ->
            Just (ChartData2D (csvTo2DData dataLines))

        Just 3 ->
            Just (ChartData3D (csvTo3DData dataLines))

        _ ->
            Nothing


csvTo2DData : List String -> List { x : Float, y : Float }
csvTo2DData lines =
    lines
        |> List.filter (\line -> String.trim line /= "" && String.left 1 line /= "#")
        |> List.map (String.split "," >> listTo2DPoint)
        |> Maybe.Extra.values


csvTo3DData : List String -> List { x : Float, y : Float, z : Float }
csvTo3DData lines =
    lines
        |> List.filter (\line -> String.trim line /= "" && String.left 1 line /= "#")
        |> List.map (String.split "," >> listTo3DPoint)
        |> Maybe.Extra.values


listTo2DPoint : List String -> Maybe { x : Float, y : Float }
listTo2DPoint list =
    case list of
        x :: y :: rest ->
            ( String.toFloat (String.trim x), String.toFloat (String.trim y) ) |> valueOfPair |> Maybe.map (\( u, v ) -> { x = u, y = v })

        _ ->
            Nothing


listTo3DPoint : List String -> Maybe { x : Float, y : Float, z : Float }
listTo3DPoint list =
    case list of
        x :: y :: z :: rest ->
            ( String.toFloat (String.trim x), String.toFloat (String.trim y), String.toFloat (String.trim z) ) |> valueOfTriple |> Maybe.map (\( u, v, w ) -> { x = u, y = v, z = w })

        _ ->
            Nothing


listTo4DPoint : List String -> Maybe { x : Float, y : Float }
listTo4DPoint list =
    case list of
        x :: y :: rest ->
            ( String.toFloat (String.trim x), String.toFloat (String.trim y) ) |> valueOfPair |> Maybe.map (\( u, v ) -> { x = u, y = v })

        _ ->
            Nothing


valueOfPair : ( Maybe a, Maybe b ) -> Maybe ( a, b )
valueOfPair ( ma, mb ) =
    case ( ma, mb ) of
        ( Just a, Just b ) ->
            Just ( a, b )

        _ ->
            Nothing


valueOfTriple : ( Maybe a, Maybe b, Maybe c ) -> Maybe ( a, b, c )
valueOfTriple ( ma, mb, mc ) =
    case ( ma, mb, mc ) of
        ( Just a, Just b, Just c ) ->
            Just ( a, b, c )

        _ ->
            Nothing


view : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
view count acc settings args id str =
    let
        data : Maybe ChartData
        data =
            csvTo2ChartData str
    in
    Element.el [ Element.width (Element.px settings.width), Element.paddingEach { left = 48, right = 0, top = 36, bottom = 36 } ]
        (rawLineChart data)


rawLineChart : Maybe ChartData -> Element msg
rawLineChart mChartData =
    case mChartData of
        Nothing ->
            Element.el [ Font.size 14, Font.color View.Color.red ] (Element.text "Line chart: Error parsing data")

        Just (ChartData2D data) ->
            rawLineChart2D data

        Just (ChartData3D data) ->
            rawLineChart3D data

        _ ->
            Element.el [ Font.size 14, Font.color View.Color.red ] (Element.text "Line chart: Error, can only handle 2D data")


rawLineChart2D : List { x : Float, y : Float } -> Element msg
rawLineChart2D data =
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


rawLineChart3D : List { x : Float, y : Float, z : Float } -> Element msg
rawLineChart3D data =
    Chart.chart
        [ Chart.Attributes.height 200
        , Chart.Attributes.width 400
        ]
        [ Chart.xLabels [ Chart.Attributes.fontSize 10 ]
        , Chart.yLabels [ Chart.Attributes.withGrid, Chart.Attributes.fontSize 10 ]
        , Chart.series .x
            [ Chart.interpolated .y [ Chart.Attributes.color Chart.Attributes.red ] []
            , Chart.interpolated .z [ Chart.Attributes.color Chart.Attributes.darkBlue ] []
            ]
            data
        ]
        |> Element.html
