module Evergreen.V631.Compiler.Lambda exposing (..)

import Evergreen.V631.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V631.Parser.Expr.Expr
    }
