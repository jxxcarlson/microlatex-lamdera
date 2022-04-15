module Evergreen.V378.Compiler.Lambda exposing (..)

import Evergreen.V378.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V378.Parser.Expr.Expr
    }
