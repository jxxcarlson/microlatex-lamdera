module Export exposing (suite2)

import Compiler.Acc
import Compiler.Util exposing (depth, size)
import Expect exposing (..)
import Markup
import Parser.Block exposing (ExpressionBlock)
import Parser.Forest exposing (Forest)
import Parser.Language exposing (Language(..))
import Render.LaTeX exposing (rawExport)
import Render.Settings exposing (defaultSettings)
import Test exposing (..)


parse : String -> Forest ExpressionBlock
parse str =
    Markup.parse MicroLaTeXLang str |> Compiler.Acc.transformST MicroLaTeXLang


parseAndExport : String -> String
parseAndExport str =
    str |> parse |> Debug.log "EXPR" |> rawExport defaultSettings


parseL0 : String -> Forest ExpressionBlock
parseL0 str =
    Markup.parse L0Lang str |> Compiler.Acc.transformST L0Lang


parseAndExportL0 : String -> String
parseAndExportL0 str =
    str |> parseL0 |> Debug.log "EXPR" |> rawExport defaultSettings


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "LaTeX export"
        [ test_ "code" (parseAndExport "\\code{foo}") "foo"
        , test_ "code 2" (parseAndExport "\\code{{}}") "\\{\\}"
        ]


suite2 : Test
suite2 =
    describe "LaTeX export from L0"
        [ -- test_ "code" (parseAndExportL0 "`foo`") "\\code{foo}"
          test_ "code {}" (parseAndExportL0 "`{}`") "\\{\\}" -- "\\code{\\{\\}}"
        ]
