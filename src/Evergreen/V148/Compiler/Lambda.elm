module Evergreen.V148.Compiler.Lambda exposing (..)

import Evergreen.V148.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V148.Parser.Expr.Expr
    }
