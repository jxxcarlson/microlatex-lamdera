module Evergreen.V410.Compiler.Lambda exposing (..)

import Evergreen.V410.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V410.Parser.Expr.Expr
    }
