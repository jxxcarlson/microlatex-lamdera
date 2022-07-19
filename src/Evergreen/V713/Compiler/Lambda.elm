module Evergreen.V713.Compiler.Lambda exposing (..)

import Evergreen.V713.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V713.Parser.Expr.Expr
    }
