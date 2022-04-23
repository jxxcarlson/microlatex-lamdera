module Evergreen.V476.Compiler.Lambda exposing (..)

import Evergreen.V476.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V476.Parser.Expr.Expr
    }
