module Evergreen.V268.Compiler.Lambda exposing (..)

import Evergreen.V268.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V268.Parser.Expr.Expr
    }
