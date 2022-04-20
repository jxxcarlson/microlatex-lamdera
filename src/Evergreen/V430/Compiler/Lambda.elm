module Evergreen.V430.Compiler.Lambda exposing (..)

import Evergreen.V430.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V430.Parser.Expr.Expr
    }
