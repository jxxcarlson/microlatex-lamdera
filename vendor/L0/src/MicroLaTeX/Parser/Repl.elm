module Parser.Repl exposing (..)

import MicroLaTeX.Parser.Expression
import Parser.Simple


p str =
    str |> MicroLaTeX.Parser.Expression.parse |> List.map Parser.Simple.simplify
