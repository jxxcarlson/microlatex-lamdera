module Evergreen.V502.Compiler.Lambda exposing (..)

import Evergreen.V502.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V502.Parser.Expr.Expr
    }
