module Evergreen.V65.Compiler.Lambda exposing (..)

import Evergreen.V65.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V65.Parser.Expr.Expr
    }
