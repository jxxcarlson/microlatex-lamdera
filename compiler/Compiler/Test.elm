module Compiler.Test exposing (tl, tm)

import Compiler.Acc
import Markup
import Parser.Language exposing (Language(..))


tl str =
    Markup.parse L0Lang str |> Compiler.Acc.transformST L0Lang


tm str =
    Markup.parse MicroLaTeXLang str |> Compiler.Acc.transformST MicroLaTeXLang
