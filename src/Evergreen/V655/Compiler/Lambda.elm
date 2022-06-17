module Evergreen.V655.Compiler.Lambda exposing (..)

import Evergreen.V655.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V655.Parser.Expr.Expr
    }
