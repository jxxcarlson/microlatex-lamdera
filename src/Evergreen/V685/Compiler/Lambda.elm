module Evergreen.V685.Compiler.Lambda exposing (..)

import Evergreen.V685.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V685.Parser.Expr.Expr
    }
