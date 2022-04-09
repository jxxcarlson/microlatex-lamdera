module Evergreen.V304.Compiler.Lambda exposing (..)

import Evergreen.V304.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V304.Parser.Expr.Expr
    }
