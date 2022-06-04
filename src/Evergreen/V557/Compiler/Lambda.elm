module Evergreen.V557.Compiler.Lambda exposing (..)

import Evergreen.V557.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V557.Parser.Expr.Expr
    }
