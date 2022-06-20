module Render.Export.Image exposing (export)

import Compiler.ASTTools
import Dict
import Parser.Expr exposing (Expr(..))
import Render.Export.Util
import Render.Settings exposing (Settings, defaultSettings)
import Render.Utility



-- width=4truein,keepaspectratio]


export1 : Settings -> List Expr -> String
export1 s exprs =
    let
        args =
            Render.Export.Util.getOneArg exprs |> String.words
    in
    case List.head args of
        Nothing ->
            "ERROR IN IMAGE"

        Just url ->
            [ "\\imagecenter{", url, "}{", "width=4truein,keepaspectratio]", "}" ] |> String.join ""


export : Settings -> List Expr -> String
export s exprs =
    let
        args =
            Render.Export.Util.getOneArg exprs |> String.words

        params =
            imageParameters s exprs

        options =
            [ "width=", params.width, ",keepaspectratio" ] |> String.join ""
    in
    case List.head args of
        Nothing ->
            "ERROR IN IMAGE"

        Just url ->
            if params.caption == "" then
                [ "\\imagecenter{", url, "}{" ++ options ++ "}" ] |> String.join ""

            else
                [ "\\imagecentercaptioned{", url, "}{" ++ options ++ "}{" ++ params.caption ++ "}" ] |> String.join ""


type alias ImageParameters =
    { caption : String
    , description : String
    , placement : String
    , width : String
    , url : String
    }


imageParameters : Render.Settings.Settings -> List Expr -> ImageParameters
imageParameters settings body =
    let
        arguments : List String
        arguments =
            Compiler.ASTTools.exprListToStringList body |> List.map String.words |> List.concat

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

        caption =
            (captionLeadString :: List.filter (\s -> not (String.contains ":" s)) remainingArguments) |> String.join " "

        dict =
            Render.Utility.keyValueDict keyValueStrings

        description =
            Dict.get "caption" dict |> Maybe.withDefault ""

        displayWidth =
            settings.width

        width : String
        width =
            case Dict.get "width" dict of
                Nothing ->
                    rescale displayWidth

                Just "fill" ->
                    rescale displayWidth

                Just w_ ->
                    case String.toInt w_ of
                        Nothing ->
                            rescale displayWidth

                        Just w ->
                            rescale w

        --placement =
        --    case Dict.get "placement" dict of
        --        Nothing ->
        --            centerX
        --
        --        Just "left" ->
        --            alignLeft
        --
        --        Just "right" ->
        --            alignRight
        --
        --        Just "center" ->
        --            centerX
        --
        --        _ ->
        --            centerX
    in
    { caption = caption, description = description, placement = "", width = width, url = url }


rescale : Int -> String
rescale k =
    (toFloat k * (8.0 / 800.0) |> String.fromFloat) ++ "truein"
