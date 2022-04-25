module Evergreen.V496.Compiler.Lambda exposing (..)

import Evergreen.V496.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V496.Parser.Expr.Expr
    }
