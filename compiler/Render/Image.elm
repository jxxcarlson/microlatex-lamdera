module Render.Image exposing (view)

import Compiler.ASTTools as ASTTools
import Dict
import Element exposing (Element, alignLeft, alignRight, centerX, column, el, px, spacing)
import Parser.Expr exposing (Expr)
import Render.Settings
import Render.Utility as Utility


type alias ImageParameters msg =
    { caption : Element msg
    , description : String
    , placement : Element.Attribute msg
    , width : Element.Length
    , url : String
    }


imageParameters : Render.Settings.Settings -> List Expr -> ImageParameters msg
imageParameters settings body =
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

        description : String
        description =
            Dict.get "caption" dict |> Maybe.withDefault ""

        caption : Element msg
        caption =
            if captionPhrase == "" then
                Element.none

            else
                Element.row [ placement, Element.width Element.fill ] [ el [ Element.width Element.fill ] (Element.text captionPhrase) ]

        displayWidth =
            settings.width

        width : Element.Length
        width =
            case Dict.get "width" dict of
                Nothing ->
                    px displayWidth

                Just "fill" ->
                    Element.fill

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
    in
    { caption = caption, description = description, placement = placement, width = width, url = url }


view : Render.Settings.Settings -> List Expr -> Element msg
view settings body =
    let
        params =
            imageParameters settings body
    in
    column [ spacing 8, Element.width (px settings.width), params.placement, Element.paddingXY 0 18 ]
        [ Element.image [ Element.width params.width, params.placement ]
            { src = params.url, description = params.description }
        , el [ params.placement ] params.caption
        ]
