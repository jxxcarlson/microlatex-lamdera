module Evergreen.V675.Compiler.Lambda exposing (..)

import Evergreen.V675.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V675.Parser.Expr.Expr
    }
