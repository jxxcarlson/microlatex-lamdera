module Evergreen.V314.Compiler.Lambda exposing (..)

import Evergreen.V314.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V314.Parser.Expr.Expr
    }
