module Evergreen.V59.Compiler.Lambda exposing (..)

import Evergreen.V59.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V59.Parser.Expr.Expr
    }
