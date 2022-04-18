module Evergreen.V409.Compiler.Lambda exposing (..)

import Evergreen.V409.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V409.Parser.Expr.Expr
    }
