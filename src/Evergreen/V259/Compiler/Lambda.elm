module Evergreen.V259.Compiler.Lambda exposing (..)

import Evergreen.V259.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V259.Parser.Expr.Expr
    }
