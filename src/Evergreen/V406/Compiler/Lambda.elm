module Evergreen.V406.Compiler.Lambda exposing (..)

import Evergreen.V406.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V406.Parser.Expr.Expr
    }
