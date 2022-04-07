module Evergreen.V280.Compiler.Lambda exposing (..)

import Evergreen.V280.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V280.Parser.Expr.Expr
    }
