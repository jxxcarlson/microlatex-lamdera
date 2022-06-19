module Render.Export.Image exposing (export)

import Parser.Expr exposing (Expr(..))
import Render.Export.Util
import Render.Settings exposing (Settings, defaultSettings)



-- width=4truein,keepaspectratio]


export : Settings -> List Expr -> String
export s exprs =
    let
        args =
            Render.Export.Util.getOneArg exprs |> String.words
    in
    case List.head args of
        Nothing ->
            "ERROR IN IMAGE"

        Just url ->
            [ "\\imagecenter{", url, "}" ] |> String.join ""


export1 : Settings -> List Expr -> String
export1 s exprs =
    let
        args =
            Render.Export.Util.getOneArg exprs |> String.words

        options =
            "width=4truein,keepaspectratio]"
    in
    case List.head args of
        Nothing ->
            "ERROR IN IMAGE"

        Just url ->
            [ "\\imagecenter{", url, "}{" ++ options ++ "}" ] |> String.join ""
