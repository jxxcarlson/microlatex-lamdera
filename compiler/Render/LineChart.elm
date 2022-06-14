module Render.LineChart exposing (view)

import Chart
import Chart.Attributes
import Compiler.Acc exposing (Accumulator)
import Element exposing (Element)
import Element.Font as Font
import List.Extra
import Maybe.Extra
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings exposing (Settings)
import View.Color


getArg : String -> List String -> Maybe String
getArg name args =
    List.filter (\item -> String.contains name item) args |> List.head


parseArg : String -> List String
parseArg arg =
    let
        parts =
            String.split ":" arg
    in
    case parts of
        [] ->
            []

        name :: [] ->
            []

        name :: argString :: [] ->
            String.split "," argString

        _ ->
            []


view : Int -> Accumulator -> Settings -> List String -> String -> String -> Element MarkupMsg
view count acc settings args id str =
    let
        _ =
            Debug.log "!! ARGS" args

        timeseries =
            getArg "timeseries" args |> Debug.log "!! TIME SERIES"

        columns =
            case getArg "columns" args of
                Nothing ->
                    Nothing

                Just argList ->
                    parseArg argList |> List.map String.toInt |> Maybe.Extra.values |> Just |> Debug.log "COLUMNS"

        data : Maybe ChartData
        data =
            csvToChartData timeseries columns str
    in
    Element.el [ Element.width (Element.px settings.width), Element.paddingEach { left = 48, right = 0, top = 36, bottom = 36 } ]
        (rawLineChart data)


type ChartData
    = ChartData2D (List { x : Float, y : Float })
    | ChartData3D (List { x : Float, y : Float, z : Float })
    | ChartData4D (List { x : Float, y : Float, z : Float, w : Float })


applyFunctions : List (a -> b) -> a -> List b
applyFunctions fs a =
    List.foldl (\f acc -> f a :: acc) [] fs |> List.reverse


select : Maybe (List Int) -> List a -> Maybe (List a)
select columns_ data =
    case columns_ of
        Nothing ->
            Just data

        Just columns ->
            let
                selectors : List (List a -> Maybe a)
                selectors =
                    List.map List.Extra.getAt columns
            in
            applyFunctions selectors data |> Maybe.Extra.combine


selectColumns : Maybe (List Int) -> List (List a) -> Maybe (List (List a))
selectColumns columns data =
    if columns == Just [] then
        Just data |> Debug.log "!! DATA (1)"

    else
        data
            |> List.Extra.transpose
            |> select columns
            |> Maybe.map List.Extra.transpose
            |> Debug.log "!! DATA (2)"


makeTimeseries : List String -> List (List String)
makeTimeseries data =
    List.indexedMap (\i datum -> [ String.fromInt i, datum ]) data


csvToChartData : Maybe String -> Maybe (List Int) -> String -> Maybe ChartData
csvToChartData timeseries columns str =
    let
        dataLines : List String
        dataLines =
            str
                |> String.lines
                |> List.filter (\line -> String.trim line /= "" && String.left 1 line /= "#")

        data : Maybe (List (List String))
        data =
            case timeseries of
                Just _ ->
                    str |> String.lines |> List.map String.trim |> makeTimeseries |> Just

                Nothing ->
                    List.map (String.split "," >> List.map String.trim) dataLines
                        |> selectColumns columns

        dimension : Maybe Int
        dimension =
            data |> Maybe.andThen List.head |> Maybe.map List.length |> Debug.log "!! DIMENSION"
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
