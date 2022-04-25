module Evergreen.V494.Parser.MathMacro exposing (..)

import Dict


type alias MacroName =
    String


type alias NumberOfArguments =
    String


type MathExpression
    = MathText String
    | Macro MacroName (List MathExpression)
    | NewCommand MacroName NumberOfArguments (List MathExpression)
    | MathList (List MathExpression)


type MacroBody
    = MacroBody Int (List MathExpression)


type alias MathMacroDict =
    Dict.Dict String MacroBody
