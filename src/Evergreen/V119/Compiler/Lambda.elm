module Evergreen.V119.Compiler.Lambda exposing (..)

import Evergreen.V119.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V119.Parser.Expr.Expr
    }
