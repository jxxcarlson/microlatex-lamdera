module Evergreen.V546.Compiler.Lambda exposing (..)

import Evergreen.V546.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V546.Parser.Expr.Expr
    }
