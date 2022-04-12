module Evergreen.V360.Compiler.Lambda exposing (..)

import Evergreen.V360.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V360.Parser.Expr.Expr
    }
