module Evergreen.V686.Compiler.Lambda exposing (..)

import Evergreen.V686.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V686.Parser.Expr.Expr
    }
