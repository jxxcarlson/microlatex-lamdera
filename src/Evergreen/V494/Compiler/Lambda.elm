module Evergreen.V494.Compiler.Lambda exposing (..)

import Evergreen.V494.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V494.Parser.Expr.Expr
    }
