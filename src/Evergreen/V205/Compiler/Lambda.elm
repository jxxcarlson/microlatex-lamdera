module Evergreen.V205.Compiler.Lambda exposing (..)

import Evergreen.V205.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V205.Parser.Expr.Expr
    }
