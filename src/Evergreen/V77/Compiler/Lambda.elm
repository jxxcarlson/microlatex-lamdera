module Evergreen.V77.Compiler.Lambda exposing (..)

import Evergreen.V77.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V77.Parser.Expr.Expr
    }
