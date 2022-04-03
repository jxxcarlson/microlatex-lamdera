module Evergreen.V225.Compiler.Lambda exposing (..)

import Evergreen.V225.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V225.Parser.Expr.Expr
    }
