module Evergreen.V382.Compiler.Lambda exposing (..)

import Evergreen.V382.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V382.Parser.Expr.Expr
    }
